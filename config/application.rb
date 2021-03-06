require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Kleineanfragen
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    config.paths.add File.join('app', 'api'), glob: File.join('**', '*.rb')

    config.autoload_paths += %W(#{Rails.root}/lib)
    config.autoload_paths += %W(#{Rails.root}/lib/constraints)
    config.autoload_paths += %W(#{Rails.root}/app/jobs)
    config.autoload_paths += %W(#{Rails.root}/app/scrapers)
    config.autoload_paths += %W(#{Rails.root}/app/extractors)
    config.autoload_paths += %W(#{Rails.root}/app/validators)
    config.autoload_paths += Dir[Rails.root.join('app', 'api', '*')]

    config.eager_load_paths += %W(#{Rails.root}/lib)

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = 'Berlin'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}').to_s]
    config.i18n.available_locales = [:de, :en]
    config.i18n.default_locale = :de

    # active job
    config.active_job.queue_adapter = :resque

    # enable cors for api
    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins '*'
        resource '*',
          headers: :any,
          methods: [:get, :head, :options],
          if: proc { |env| env['HTTP_HOST'].start_with? 'api.' }
      end
    end

    # Ohai developers!
    config.action_dispatch.default_headers.merge!('X-Developer' => 'Looking for raw data? Try /data.')

    # applicaton config:
    # path for storing paper pdfs
    config.x.paper_storage = Rails.root.join('data')
    # path for storing downloaded exports
    config.x.export_storage = Rails.root.join('data')
    # User-Agent for scraping and download
    config.x.user_agent = 'kleineanfragen-scraper (scraper@kleineanfragen.de)'
    # Tika Server URL for extracting text from papers
    config.x.tika_server = ENV['TIKA_SERVER_URL'] || false
    # Nomenklatura API Key
    config.x.nomenklatura_api_key = ENV['NOMENKLATURA_APIKEY'] || false
    # OCR.Space API Key
    config.x.ocrspace_api_key = ENV['OCRSPACE_APIKEY'] || false
    # used email addresses
    config.x.email_from = 'kleineAnfragen <noreply@kleineanfragen.de>'
    config.x.email_support = 'kleineAnfragen support <hallo@kleineanfragen.de>'
    # set from address
    config.action_mailer.default_options = { from: config.x.email_from }
    # report slack webhook url
    config.x.report_slack_webhook = ENV['REPORT_SLACK_WEBHOOK']
    # pubsubhubbub hub url
    config.x.push_hubs = ENV['PUSH_HUB'].split(',').reject(&:blank?).map(&:strip) unless ENV['PUSH_HUB'].nil?
    # Push OCR token to update paper contents from remote
    config.x.push_ocr_token = ENV['PUSH_OCR_TOKEN']
    # Email token to enable incoming email parsing
    config.x.email_token = ENV['EMAIL_TOKEN']
  end
end
