module ActiveadminSettings
  module SettingMethods
    def self.included(base)
      base.validates :name, presence: true, uniqueness: { scope: :locale }, length: { minimum: 1 }
      base.extend ClassMethods
    end

    # Class
    module ClassMethods
      def initiate_setting(name, locale = nil)
        locale ||= I18n.default_locale
        setting = self.new(name: name, locale: locale.to_s)
        if setting.type == "text" or setting.type == "html"
          setting.string = setting.default_value
        end
        setting.save
        setting
      end
    end

    # Instance
    def type
      (ActiveadminSettings.all_settings.dig(name, "type") || "string").to_s
    end

    def description
      ActiveadminSettings.all_settings.dig(name, "description").to_s
    end

    def group
      ActiveadminSettings.all_settings.dig(name, "group").to_s
    end

    def default_value(locale = nil)
      locale ||= self[:locale] || I18n.default_locale
      default_value = ActiveadminSettings.all_settings.dig(name, "default_value")
      if default_value.is_a? Hash
        default_value = default_value[locale.to_s]
        default_value ||= default_value[I18n.default_locale.to_s]
        default_value ||= ""
      else
        default_value = (default_value || "").to_s
      end

      if type == "file" and not default_value.include? '//'
        default_value = ActionController::Base.helpers.asset_path(default_value)
      end

      default_value
    end

    def value
      val = respond_to?(type) ? send(type).to_s : send(:string).to_s
      val = default_value if val.empty?
      val.html_safe
    end
  end

  class Setting < ActiveRecord::Base
      self.table_name = 'settings'  # ← ВАЖНО: явное указание таблицы

      include SettingMethods

      unless Rails::VERSION::MAJOR > 3 && !defined? ProtectedAttributes
        attr_accessible :name, :string, :file, :remove_file, :locale
      end

      Snapshot = Struct.new(:values, :at)

      @snapshot = nil
      @snapshot_lock = Mutex.new

      after_commit { self.class.reset_snapshot }

      class << self
        def value(name, locale = nil)
          locale ||= I18n.locale
          key = [name.to_s, locale.to_s]
          values = snapshot_values
          return values[key] if values.key?(key)

          find_or_create_by(:name => name, :locale => locale).value
        end

        def reset_snapshot
          @snapshot_lock.synchronize { @snapshot = nil }
        end

        private

        def snapshot_values
          ttl = ActiveadminSettings.snapshot_ttl.to_f
          return {} unless ttl > 0

          current = @snapshot
          return current.values if fresh?(current, ttl)

          @snapshot_lock.synchronize do
            current = @snapshot
            return current.values if fresh?(current, ttl)

            snapshot = Snapshot.new(load_values, monotonic_now)
            @snapshot = snapshot
            snapshot.values
          end
        end

        def fresh?(snapshot, ttl)
          snapshot && (monotonic_now - snapshot.at) < ttl
        end

        def load_values
          values = {}
          all.each do |setting|
            values[[setting.name, setting.locale.to_s]] = setting.value.freeze
          rescue StandardError
            next
          end
          values.freeze
        end

        def monotonic_now
          Process.clock_gettime(Process::CLOCK_MONOTONIC)
        end
      end
  end
end