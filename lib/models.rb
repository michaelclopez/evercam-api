db = Sequel.connect(Evercam::Config[:database])
Sequel::Model.plugin :boolean_readers
Sequel::Model.plugin :association_proxies
Sequel::Model.plugin :timestamps, update_on_create: true

if :postgres == db.adapter_scheme
  db.extension :pg_array
end

require_relative './models/device'
require_relative './models/stream'
require_relative './models/client'
require_relative './models/access_token'
require_relative './models/access_token_right'
require_relative './models/access_scope'
require_relative './models/country'
require_relative './models/user'

