web: bundle exec puma -C config/puma.rb
worker: bundle exec sidekiq -c ${SIDEKIQ_CONCURRENCY:-5} -r ./scripts/sidekiq_setup.rb -C ./config/sidekiq.yml
