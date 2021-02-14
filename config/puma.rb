if ENV["RAILS_ENV"] == "production"
  environment ENV.fetch("RAILS_ENV")

  pidfile "#{File.expand_path('../../tmp/pids/puma.pid', __FILE__)}"
  bind "unix://#{File.expand_path('../../tmp/sockets/puma.sock', __FILE__)}"

  num_workers = ENV.fetch("WEB_CONCURRENCY") { 2 }.to_i
  min_threads = ENV.fetch("WEB_CONCURRENCY_MIN_THREADS") { 4 }.to_i
  max_threads = ENV.fetch("WEB_CONCURRENCY_MAX_THREADS") { 8 }.to_i

  workers num_workers
  threads min_threads, max_threads

  preload_app!

  plugin :appsignal
end
