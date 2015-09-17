workers Integer(ENV['WEB_CONCURRENCY'] || 4)
threads_count = Integer(ENV['MAX_THREADS'] || 5)
threads threads_count, threads_count

preload_app!

rackup DefaultRackup
port ENV['PORT'] || 9293
environment ENV['RACK_ENV'] || 'development'

on_worker_boot do
  # force Sequel's thread pool to be refreshed
  Sequel::DATABASES.each(&:disconnect)
end
