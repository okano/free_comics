require_relative 'boot'

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
# require "active_record/railtie"
# require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "action_cable/engine"
require "sprockets/railtie"
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module FreeComics
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
    config.autoload_paths += %W(#{config.root}/lib)
    config.enable_dependency_loading = true

    # クローラ関連
    config.url_base_linemanga = 'https://manga.line.me'
    config.url_list_linemanga = '/daily_list?week_day='
    config.url_detail_linemanga = '/product/periodic?id='
    config.url_detail_all_linemanga = '/api/book/product_list?need_read_info=1&rows=1000&is_periodic=1&product_id='
    config.url_viewer_linemanga = '/book/viewer?id='
    # サムネイル格納場所
    #config.cdn_prefix = 'fc'
    config.cdn_folder_linemanga = 'lm'

  end
end
