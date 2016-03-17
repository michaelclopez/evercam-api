require 'dotenv'
require 'sequel'
require 'pusher'

Dotenv.load
Sequel::Model.db = Sequel.connect("#{ENV['DATABASE_URL']}", max_connections: 5)

require 'evercam_misc'
require 'evercam_models'
require_relative '../lib/workers'
Snapshot.db = Sequel.connect("#{ENV['SNAPSHOT_DATABASE_URL']}", max_connections: 5)
