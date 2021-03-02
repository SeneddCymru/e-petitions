if defined?(Shoryuken)
  Rails.application.config.to_prepare do
    Shoryuken.configure_server do |config|
      # Output Rails logs to log/shoryuken.log.
      Rails.logger = Shoryuken::Logging.logger
      Rails.logger.level = Rails.application.config.log_level

      concurrency = ENV.fetch("WEB_CONCURRENCY_MAX_THREADS") { 16 }.to_i
      queue = ENV.fetch("QUEUE_NAME")

      # Manually configure processing group and queue.
      # Add a delay of 5 seconds to reduce API requests.
      config.add_group("default", concurrency, delay: 5)
      config.add_queue(queue, 1, "default")

      # Cache visibility timeout to reduce API requests.
      config.cache_visibility_timeout = true

      # Manually register the worker
      config.register_worker(queue, Notifications::Worker)
    end
  end
end
