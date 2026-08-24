require "activeadmin-settings/version"

module ActiveadminSettings
  require 'activeadmin-settings/engine'
  require 'activeadmin-settings/helper'
  require 'activeadmin-settings/routing'

  IMAGE_TYPES = [ 'image/jpeg',
                  'image/png',
                  'image/gif',
                  'image/jpg',
                  'image/pjpeg',
                  'image/tiff',
                  'image/x-png' ]

  mattr_accessor :image_file_types
  @@image_file_types = ["jpg", "jpeg", "png", "gif", "tiff"]
  
  mattr_accessor :config_file
  @@config_file = "config/activeadmin_settings.yml"

  mattr_accessor :snapshot_ttl
  @@snapshot_ttl = 600

  # Load configuration from config/activeadmin_settings.yml
  def self.load_config
    @load_config ||= begin
      config_file = ::Rails.root.join(@@config_file)
      data = YAML::load(ERB.new(IO.read(config_file)).result) if File.exist?(config_file)
      data || {}
    end
  end

  def self.all_settings
    @all_settings ||= load_config.each_with_object({}) do |(_key, settings), all|
      all.merge!(settings)
    end
  end

  def self.reload_config!
    @load_config = nil
    @all_settings = nil
  end

  def self.groups
    @groups = []
    load_config.each do |key, settings|
      @groups << {:name     => key,
                  :slug     => key.downcase.gsub(" ", "_"),
                  :default_settings => settings,
                  :settings => [] }
    end
    @groups
  end
end
