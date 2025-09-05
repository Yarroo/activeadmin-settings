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

      def self.value(name, locale)
        find_or_create_by(:name => name, :locale => (locale || I18n.locale)).value
      end
  end
end