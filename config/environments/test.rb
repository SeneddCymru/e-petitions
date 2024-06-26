# The test environment is used exclusively to run your application's
# test suite. You never need to work with it otherwise. Remember that
# your test database is "scratch space" for the test suite and is wiped
# and recreated between test runs. Don't rely on the data there!

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # The test environment is used exclusively to run your application's
  # test suite. You never need to work with it otherwise. Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs. Don't rely on the data there!
  config.cache_classes = true

  # Do not eager load code on boot. This avoids loading your whole application
  # just for the purpose of running a single test. If you are using a tool that
  # preloads Rails for running tests, you may have to set it to true.
  config.eager_load = false

  # Configure public file server for tests with Cache-Control for performance.
  config.public_file_server.enabled = true
  config.public_file_server.headers = {
    'Cache-Control' => 'public, max-age=3600'
  }

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Raise exceptions instead of rendering exception templates.
  config.action_dispatch.show_exceptions = false

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = true

  # Set the HSTS headers to include subdomains
  config.ssl_options[:hsts] = { expires: 365.days, subdomains: true }

  # Enable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = true

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  # Set default_url_options for links in emails
  config.action_mailer.default_url_options = { host: ENV.fetch('EPETITIONS_HOST_EN') }

  # Randomize the order test cases are executed.
  config.active_support.test_order = :random

  # Print deprecation notices to the stderr.
  config.active_support.deprecation = :stderr

  # Disable asset digests so that test values don't change.
  config.assets.digest = false

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  # Store files locally.
  config.active_storage.service = :test

  # Use webmock to disable net connections except for localhost and exceptions
  WebMock.disable_net_connect!(
    allow_localhost: true,
    allow: 'chromedriver.storage.googleapis.com'
  )
end
