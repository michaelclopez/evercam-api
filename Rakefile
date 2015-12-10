require 'rake'
require 'logjam'
require 'evercam_misc'
require 'active_support/core_ext/numeric/time'

if :development == Evercam::Config.env
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
  task default: :spec
end

namespace :db do
  require 'sequel'
  Sequel.extension :migration, :pg_json, :pg_array

  task :migrate do
    envs = [Evercam::Config.env]
    envs << :test if :development == envs[0]
    envs.each do |env|
      db_url = Evercam::Config.settings[env][:database]
      puts "migrate: #{env} with database url #{db_url}"
      db = Sequel.connect(db_url)
      Sequel::Migrator.run(db, 'migrations')
    end
  end

  task :rollback do
    envs = [Evercam::Config.env]
    envs << :test if :development == envs[0]
    envs.each do |env|
      db = Sequel.connect(Evercam::Config.settings[env][:database])
      migrations = db[:schema_migrations].order(:filename).to_a
      migration = 0
      if migrations.length > 1
        match = /^(\d+).+$/.match(migrations[-2][:filename])
        migration = match[1].to_i if match
      end

      Sequel::Migrator.run(db, 'migrations', target: migration)
      puts "migrate: #{env}, ('#{migration}')"
    end
  end

  task :migrate_snapshots do
    envs = [Evercam::Config.env]
    envs << :test if :development == envs[0]
    envs.each do |env|
      db_url = Evercam::Config.settings[env][:snaps_database]
      puts "migrate: #{env} with database url #{db_url}"
      db = Sequel.connect(db_url)
      Sequel::Migrator.run(db, 'migrations')
    end
  end

  task :rollback_snapshots do
    envs = [Evercam::Config.env]
    envs << :test if :development == envs[0]
    envs.each do |env|
      db = Sequel.connect(Evercam::Config.settings[env][:snaps_database])
      migrations = db[:schema_migrations].order(:filename).to_a
      migration = 0
      if migrations.length > 1
        match = /^(\d+).+$/.match(migrations[-2][:filename])
        migration = match[1].to_i if match
      end

      Sequel::Migrator.run(db, 'migrations', target: migration)
      puts "migrate: #{env}, ('#{migration}')"
    end
  end

  task :seed do
    db_url = Evercam::Config.settings[:development][:database]
    Sequel.connect(db_url)
    require 'evercam_models'

    country = Country.create(iso3166_a2: "ad", name: "Andorra")

    user = User.create(
      username: "dev",
      password: "dev",
      firstname: "Awesome",
      lastname: "Dev",
      email: "dev@localhost.dev",
      country_id: country.id,
      api_id: SecureRandom.hex(4),
      api_key: SecureRandom.hex
    )

    hikvision_vendor = Vendor.create(
      exid: "hikvision",
      known_macs: ["00:0C:43", "00:40:48", "8C:E7:48", "00:3E:0B", "44:19:B7"],
      name: "Hikvision Digital Technology"
    )

    hikvision_model = VendorModel.create(
      vendor_id: hikvision_vendor.id,
      name: "Default",
      config: {
        "auth" => {
          "basic" => {
            "username" => "admin",
            "password" => "12345"
          }
        },
        "snapshots" => {
          "h264" => "h264/ch1/main/av_stream",
          "lowres" => "",
          "jpg" => "Streaming/Channels/1/picture",
          "mpeg4" => "mpeg4/ch1/main/av_stream",
          "mobile" => "",
          "mjpg" => ""
        }
      },
      exid: "hikvision_default",
      jpg_url: "Streaming/Channels/1/picture",
      h264_url: "h264/ch1/main/av_stream",
      mjpg_url: "",
      shape: "Dome",
      resolution: "640x480",
      official_url: "",
      audio_url: "",
      more_info: "",
      poe: true,
      wifi: false,
      onvif: true,
      psia: true,
      ptz: false,
      infrared: true,
      varifocal: true,
      sd_card: false,
      upnp: false,
      audio_io: true,
      discontinued: false,
      username: "admin",
      password: "12345"
    )

    Camera.create(
      name: "Phony Camera",
      exid: "phony_camera",
      owner_id: user.id,
      is_public: true,
      config: {
        "internal_rtsp_port" => "",
        "internal_http_port" => "",
        "internal_host" => "",
        "external_rtsp_port" => "",
        "external_http_port" => 9000,
        "external_host" => "127.0.0.1",
        "snapshots" => {
          "jpg" => "/snapshot.jpg"
        },
        "auth" => {
          "basic" => {
            "username" => "",
            "password" => ""
          }
        }
      }
    )

    Camera.create(
      name: "Hikvision Devcam",
      exid: "hikvision_devcam",
      owner_id: user.id,
      is_public: false,
      model_id: hikvision_model.id,
      config: {
        "internal_rtsp_port" => "",
        "internal_http_port" => "",
        "internal_host" => "",
        "external_rtsp_port" => 9101,
        "external_http_port" => 8101,
        "external_host" => "5.149.169.19",
        "snapshots" => {
          "jpg" => "/Streaming/Channels/1/picture"
        },
        "auth" => {
          "basic" => {
            "username" => "admin",
            "password" => "mehcam"
          }
        }
      }
    )

    Camera.create(
      name: "Y-cam DevCam",
      exid: "y_cam_devcam",
      owner_id: user.id,
      is_public: false,
      config: {
        "internal_rtsp_port" => "",
        "internal_http_port" => "",
        "internal_host" => "",
        "external_rtsp_port" => "",
        "external_http_port" => 8013,
        "external_host" => "5.149.169.19",
        "snapshots" => {
          "jpg" => "/snapshot.jpg"
        },
        "auth" => {
          "basic" => {
            "username" => "",
            "password" => ""
          }
        }
      }
    )

    Camera.create(
      name: "Evercam Devcam",
      exid: "evercam-remembrance-camera-0",
      owner_id: user.id,
      is_public: true,
      model_id: hikvision_model.id,
      config: {
        "internal_rtsp_port" => 0,
        "internal_http_port" => 0,
        "internal_host" => "",
        "external_rtsp_port" => 90,
        "external_http_port" => 80,
        "external_host" => "149.5.38.22",
        "snapshots" => {
          "jpg" => "/Streaming/Channels/1/picture"
        },
        "auth" => {
          "basic" => {
            "username" => "guest",
            "password" => "guest"
          }
        }
      }
    )
  end
end

namespace :tmp do
  task :clear do
    require 'dalli'
    require_relative 'lib/services'

    Evercam::Services.dalli_cache.flush_all
    puts "Memcached cache flushed!"
  end
end

desc "Import models_data_all.csv from S3 and add extra specs data to Evercam Models"
task :import_vendor_models, [:vendorexid] do |t, args|
  require 'evercam_models'
  require 'aws-sdk'
  require 'open-uri'
  require 'smarter_csv'

  AWS.config(
    :access_key_id => ENV['AWS_ACCESS_KEY_ID'],
    :secret_access_key => ENV['AWS_SECRET_KEY'],
    # disable this key if source bucket is in US
    :s3_endpoint => 's3-eu-west-1.amazonaws.com'
  )
  s3 = AWS::S3.new
  assets = s3.buckets['evercam-public-assets']
  csv = assets.objects['models_data_all.csv']

  if csv.nil?
    puts " No CSV file found"
  else
    puts " CSV file found"
  end

  if !Dir.exists?("temp/")
    puts " Create temp/"
    Dir.mkdir("temp/")
  end

  puts "\n Importing models_data_all.csv... \n"
  File.open("temp/models_data_all.csv", "wb") do |f|
    f.write(csv.read)
    puts " 'models_data_all.csv' imported from AWS S3 \n"
  end

  puts "\n Reading data from 'models_data_all.csv' for #{args[:vendorexid]} \n"
  File.open("temp/models_data_all.csv", "r:ISO-8859-15:UTF-8") do |file|
    v = Vendor.find(:exid => args[:vendorexid])
    if v.nil?
      # try creating new vendor if does not exist already
      if args[:vendorexid] =~ /^[a-z0-9\-_]+$/ and args[:vendorexid].length > 3
        v = Vendor.new(
          exid: args[:vendorexid],
          name: args[:vendorexid].upcase,
          known_macs: ['']
        )
        v.save
        puts "    V += " + v.id.to_s + ", " + args[:vendorexid] + ", " + args[:vendorexid].upcase
      else
        puts ' New vendor ID can only contain lower case letters, numbers, hyphens and underscore. Minimum length is 4.'
      end
    else
      puts "    V == " + v.exid
    end
    d = VendorModel.find(exid: v.exid + "_default")
    if d.nil?
      # try creating default vendor model if does not exist already
      d = VendorModel.new(
        exid: v.exid + "_default",
        name: "Default",
        vendor_id: v.id,
        config: {}
      )
      d.save
      puts "    D += " + d.exid.to_s + ", " + d.name
    else
      puts "    D == " + d.exid.to_s + ", " + d.name
    end

    SmarterCSV.process(file).each do |vm|
      next if !(vm[:vendor_id].downcase == args[:vendorexid].downcase)
      original_vm = vm.clone

      m = VendorModel.where(:exid => vm[:model].to_s).first

      # Next if vendor model not found
      next if m.nil?

      puts "    M == " + m.exid + ", " + m.name

      shape = vm[:shape].nil? ? "" : vm[:shape]
      resolution = vm[:resolution].nil? ? "" : vm[:resolution]
      official_url = vm[:official_url].nil? ? "" : vm[:official_url]
      audio_url = vm[:audio_url].nil? ? "" : vm[:audio_url]
      more_info = vm[:more_info].nil? ? "" : vm[:more_info]
      poe = vm[:poe].nil? ? "False" : vm[:poe] == "t" ? "True" : "False"
      wifi = vm[:wifi].nil? ? "False" : vm[:wifi] == "t" ? "True" : "False"
      onvif = vm[:onvif].nil? ? "False" : vm[:onvif] == "t" ? "True" : "False"
      psia = vm[:psia].nil? ? "False" : vm[:psia] == "t" ? "True" : "False"
      ptz = vm[:ptz].nil? ? "False" : vm[:ptz] == "t" ? "True" : "False"
      infrared = vm[:infrared].nil? ? "False" : vm[:infrared] == "t" ? "True" : "False"
      varifocal = vm[:varifocal].nil? ? "False" : vm[:varifocal] == "t" ? "True" : "False"
      sd_card = vm[:sd_card].nil? ? "False" : vm[:sd_card] == "t" ? "True" : "False"
      upnp = vm[:upnp].nil? ? "False" : vm[:upnp] == "t" ? "True" : "False"
      audio_io = vm[:audio_io].nil? ? "False" : vm[:audio_io] == "t" ? "True" : "False"
      discontinued = vm[:discontinued].nil? ? "False" : vm[:discontinued] == "t" ? "True" : "False"

      # set up specs
      m.values[:shape] = shape
      m.values[:resolution] = resolution
      m.values[:official_url] = official_url
      m.values[:poe] = poe
      m.values[:wifi] = wifi
      m.values[:onvif] = onvif
      m.values[:psia] = psia
      m.values[:ptz] = ptz
      m.values[:infrared] = infrared
      m.values[:varifocal] = varifocal
      m.values[:sd_card] = sd_card
      m.values[:upnp] = upnp
      m.values[:audio_io] = audio_io
      m.values[:discontinued] = discontinued

      # set up snapshot urls
      if m.values[:config].has_key?("snapshots")
        if m.values[:config]["snapshots"].has_key?("jpg")
          m.values[:jpg_url] = m.values[:config]["snapshots"]["jpg"]
        end
        if m.values[:config]["snapshots"].has_key?("h264")
          m.values[:h264_url] = m.values[:config]["snapshots"]["h264"]
        end
        if m.values[:config]["snapshots"].has_key?("mjpg")
          m.values[:mjpg_url] = m.values[:config]["snapshots"]["mjpg"]
        end
      end

      # set up basic auth
      if m.values[:config].has_key?("auth") && m.values[:config]["auth"].has_key?("basic")
        if m.values[:config]["auth"]["basic"].has_key?("username")
          m.values[:username] = m.values[:config]["auth"]["basic"]["username"]
        end
        if m.values[:config]["auth"]["basic"].has_key?("password")
          m.values[:password] = m.values[:config]["auth"]["basic"]["password"]
        end
      end

      ######
      m.save
      ######

      puts "      => " + m.exid + ", " + m.name
    end
  end
end

desc "Import cambase_models.csv from S3 and fix Evercam models data for given vendor onlys"
task :import_vendor_data, [:vendorexid] do |t, args|
  require 'evercam_models'
  require 'aws-sdk'
  require 'open-uri'
  require 'smarter_csv'

  AWS.config(
    :access_key_id => ENV['AWS_ACCESS_KEY_ID'],
    :secret_access_key => ENV['AWS_SECRET_KEY'],
    # disable this key if source bucket is in US
    :s3_endpoint => 's3-eu-west-1.amazonaws.com'
  )
  s3 = AWS::S3.new
  assets = s3.buckets['evercam-public-assets']
  csv = assets.objects['models_data.csv']

  if csv.nil?
    puts " No CSV file found"
  else
    puts " CSV file found"
  end

  if !Dir.exists?("temp/")
    puts " Create temp/"
    Dir.mkdir("temp/")
  end

  puts "\n Importing models_data.csv... \n"
  File.open("temp/models_data.csv", "wb") do |f|
    f.write(csv.read)
    puts " 'models_data.csv' imported from AWS S3 \n"
  end

  puts "\n Reading data from 'models_data.csv' for #{args[:vendorexid]} \n"
  File.open("temp/models_data.csv", "r:ISO-8859-15:UTF-8") do |file|
    v = Vendor.find(:exid => args[:vendorexid])
    if v.nil?
      if args[:vendorexid] =~ /^[a-z0-9\-_]+$/ and args[:vendorexid].length > 3
        v = Vendor.new(
          exid: args[:vendorexid],
          name: args[:vendorexid].upcase,
          known_macs: ['']
        )
        v.save
        puts "    V += " + v.id.to_s + ", " + args[:vendorexid] + ", " + args[:vendorexid].upcase
      else
        puts ' Vendor ID can only contain lower case letters, numbers, hyphens and underscore. Minimum length is 4.'
      end
    end
    d = VendorModel.find(exid: v.exid + "_default")
    if d.nil?
      d = VendorModel.new(
        exid: v.exid + "_default",
        name: "Default",
        vendor_id: v.id,
        config: {}
      )
      d.save
      puts "    D += " + d.exid.to_s + ", " + d.name
    else
      puts "    D == " + d.exid.to_s + ", " + d.name
    end

    SmarterCSV.process(file).each do |vm|
      next if !(vm[:vendor_id].downcase == args[:vendorexid].downcase)
      original_vm = vm.clone
      puts "    + " + v.exid + "." + vm[:model].to_s

      if !d.nil?
        Rake::Task["fix_model"].invoke(d, vm[:jpg_url], vm[:h264_url], vm[:mjpg_url], vm[:default_username], vm[:default_password])
      end

      m = VendorModel.where(:exid => vm[:model].to_s).first
      if m.nil?
        m = VendorModel.new(
          exid: vm[:model].to_s,
          name: vm[:model].upcase,
          vendor_id: v.id,
          config: {}
        )
        puts "     VM += " + v.id.to_s + ", " + vm[:model] + ", " + vm[:model].upcase
      else
        puts "     VM ^= " + m.vendor_id.to_s + ", " + m.exid + ", " + m.name
      end

      jpg_url = vm[:jpg_url].nil? ? "" : vm[:jpg_url]
      h264_url = vm[:h264_url].nil? ? "" : vm[:h264_url]
      mjpg_url = vm[:mjpg_url].nil? ? "" : vm[:mjpg_url]
      default_username = vm[:default_username].nil? ? "" : vm[:default_username].to_s
      default_password = vm[:default_password].nil? ? "" : vm[:default_password].to_s

      ### This does not call the method if any of the parameters is blank
      #Rake::Task["fix_model"].invoke(m, jpg_url, h264_url, mjpg_url, default_username, default_password)

      m.name = m.name.upcase

      if !jpg_url.blank?
        m.jpg_url = jpg_url
        if m.values[:config].has_key?('snapshots')
          if m.values[:config]['snapshots'].has_key?('jpg')
            m.values[:config]['snapshots']['jpg'] = jpg_url
          else
            m.values[:config]['snapshots'].merge!({:jpg => jpg_url})
          end
        else
          m.values[:config].merge!({'snapshots' => { :jpg => jpg_url}})
        end
      end

      if !h264_url.blank?
        m.h264_url = h264_url
        if m.values[:config].has_key?('snapshots')
          if m.values[:config]['snapshots'].has_key?('h264')
            m.values[:config]['snapshots']['h264'] = h264_url
          else
            m.values[:config]['snapshots'].merge!({:h264 => h264_url})
          end
        else
          m.values[:config].merge!({'snapshots' => { :h264 => h264_url}})
        end
      end

      if !mjpg_url.blank?
        m.mjpg_url = mjpg_url
        if m.values[:config].has_key?('snapshots')
          if m.values[:config]['snapshots'].has_key?('mjpg')
            m.values[:config]['snapshots']['mjpg'] = mjpg_url
          else
            m.values[:config]['snapshots'].merge!({:mjpg => mjpg_url})
          end
        else
          m.values[:config].merge!({'snapshots' => { :mjpg => mjpg_url}})
        end
      end

      if default_username or default_password
        m.values[:config].merge!({
          'auth' => {
            'basic' => {
              'username' => default_username.to_s.empty? ? '' : default_username.to_s,
              'password' => default_password.to_s.empty? ? '' : default_password.to_s
            }
          }
        })
      end

      puts "       " + m.values[:config].to_s

      ######
      m.save
      ######

      puts "       FIXED: #{m.exid}"
    end
  end
end


task :fix_model, [:m, :jpg_url, :h264_url, :mjpg_url, :default_username, :default_password] do |t, args|
  args.with_defaults(:jpg_url => "", :h264_url => "", :mjpg_url => "", :default_username => "", :default_password => "")

  m = args.m
  jpg_url = args.jpg_url.nil? ? "" : args.jpg_url
  h264_url = args.h264_url.nil? ? "" : args.h264_url
  mjpg_url = args.mjpg_url.nil? ? "" : args.mjpg_url
  default_username = args.default_username.nil? ? "" : args.default_username.to_s
  default_password = args.default_password.nil? ? "" : args.default_password.to_s

  m.name = m.name.upcase

  if !jpg_url.blank?
    m.jpg_url = jpg_url
    if m.values[:config].has_key?('snapshots')
      if m.values[:config]['snapshots'].has_key?('jpg')
        m.values[:config]['snapshots']['jpg'] = jpg_url
      else
        m.values[:config]['snapshots'].merge!({:jpg => jpg_url})
      end
    else
      m.values[:config].merge!({'snapshots' => { :jpg => jpg_url}})
    end
  end

  if !h264_url.blank?
    m.h264_url = h264_url
    if m.values[:config].has_key?('snapshots')
      if m.values[:config]['snapshots'].has_key?('h264')
        m.values[:config]['snapshots']['h264'] = h264_url
      else
        m.values[:config]['snapshots'].merge!({:h264 => h264_url})
      end
    else
      m.values[:config].merge!({'snapshots' => { :h264 => h264_url}})
    end
  end

  if !mjpg_url.blank?
    m.mjpg_url = mjpg_url
    if m.values[:config].has_key?('snapshots')
      if m.values[:config]['snapshots'].has_key?('mjpg')
        m.values[:config]['snapshots']['mjpg'] = mjpg_url
      else
        m.values[:config]['snapshots'].merge!({:mjpg => mjpg_url})
      end
    else
      m.values[:config].merge!({'snapshots' => { :mjpg => mjpg_url}})
    end
  end

  if default_username or default_password
    m.values[:config].merge!({
      'auth' => {
        'basic' => {
          'username' => default_username.to_s.empty? ? '' : default_username.to_s,
          'password' => default_password.to_s.empty? ? '' : default_password.to_s
        }
      }
    })
  end

  puts "       " + m.values[:config].to_s

  m.save

  puts "       FIXED: #{m.exid}"
end

task :fix_models_data do
  VendorModel.all.each do |model|
    updated = false
    ## Upcase all model names except Default
    if model.name.downcase != "default"
      if model.name != model.name.upcase
        model.name = model.name.upcase
        updated = true
      end
    end

    ## Remove None from model Urls
    if !model.jpg_url.blank? && (model.jpg_url.downcase == "none" || model.jpg_url.downcase == "jpg" || model.jpg_url.length < 4)
      model.jpg_url = ""
      if model.values[:config].has_key?('snapshots')
        if model.values[:config]['snapshots'].has_key?('jpg')
          model.values[:config]['snapshots']['jpg'] = ""
          updated = true
        else
          model.values[:config]['snapshots'].merge!({:jpg => ""})
          updated = true
        end
      end
    end
    if !model.h264_url.blank? && (model.h264_url.downcase == "none" || model.h264_url.downcase == "h264" || model.h264_url.length < 4)
      model.h264_url = ""
      if model.values[:config].has_key?('snapshots')
        if model.values[:config]['snapshots'].has_key?('h264')
          model.values[:config]['snapshots']['h264'] = ""
          updated = true
        else
          model.values[:config]['snapshots'].merge!({:h264 => ""})
          updated = true
        end
      end
    end
    if !model.mjpg_url.blank? && (model.mjpg_url.downcase == "none" || model.mjpg_url.downcase == "mjpg" || model.mjpg_url.length < 4)
      model.mjpg_url = ""
      if model.values[:config].has_key?('snapshots')
        if model.values[:config]['snapshots'].has_key?('mjpg')
          model.values[:config]['snapshots']['mjpg'] = ""
          updated = true
        else
          model.values[:config]['snapshots'].merge!({:mjpg => ""})
          updated = true
        end
      end
    end

    if updated
      puts " - " + model.name + ", " + model.exid
      model.save
    end
  end
end


task :import_cambase_data do
  file = File.read("models.json")

  models = JSON.parse(file)

  models.each do |model|
    vendor = Vendor.where(:exid => model['vendor_id']).first
    if vendor.nil?
      puts "Vendor #{model['vendor_id']} doesn't exist yet, creating it"
      vendor = Vendor.create(
        exid: model['vendor_id'],
        name: model['vendor_name'],
        known_macs: ['']
      )
    end

    vendor_model = VendorModel.where(:exid => model['id']).first
    if vendor_model.nil?
      puts "Model #{model['id']} doesn't exist yet, adding it"
      VendorModel.create(
        vendor_id: vendor.id,
        exid: model['id'],
        name: model['name'],
        config: model['config']
      )
    else
      puts "Model #{model['id']} already exist, skipping it"
    end
  end
end

task :export_snapshots_to_s3 do

  Sequel.connect(Evercam::Config[:database])

  require 'evercam_models'
  require 'aws-sdk'

  begin
    Snapshot.set_primary_key :id

    Snapshot.where(notes: "Evercam Capture auto save").or("notes IS NULL").each do |snapshot|
      puts "S3 export: Started migration for snapshot #{snapshot.id}"
      camera = snapshot.camera
      filepath = "#{camera.exid}/snapshots/#{snapshot.created_at.to_i}.jpg"

      unless snapshot.data == 'S3'
        Evercam::Services.snapshot_bucket.objects.create(filepath, snapshot.data)

        snapshot.data = 'S3'
        snapshot.save
      end

      puts "S3 export: Snapshot #{snapshot.id} from camera #{camera.exid} moved to S3"
      puts "S3 export: #{Snapshot.where(notes: "Evercam Capture auto save").or("notes IS NULL").count} snapshots left \n\n"
    end

  rescue Exception => e
    log.warn(e)
  end
end

task :export_thumbnails_to_s3 do
  Sequel.connect(Evercam::Config[:database])

  require 'active_support'
  require 'active_support/core_ext'
  require 'evercam_models'
  require 'aws-sdk'

  begin
    Camera.each do |camera|
      filepath = "#{camera.exid}/snapshots/latest.jpg"

      unless camera.preview.blank?
        Evercam::Services.snapshot_bucket.objects.create(filepath, camera.preview)
        image = Evercam::Services.snapshot_bucket.objects[filepath]
        camera.thumbnail_url = image.url_for(:get, {expires: 10.years.from_now, secure: true}).to_s
        camera.save

        puts "S3 export: Thumbnail for camera #{camera.exid} exported to S3"
      end
    end

  rescue Exception => e
    log.warn(e)
  end
end

task :send_camera_data_to_elixir_server, [:total, :paid_only] do |t, args|
  Sequel.connect(Evercam::Config[:database])

  require 'active_support'
  require 'active_support/core_ext'
  require 'evercam_models'

  recording_cameras = [
    "dancecam",
    "centralbankbuild",
    "carrollszoocam",
    "gpocam",
    "wayra-agora",
    "wayrahikvision",
    "zipyard-navan-foh",
    "zipyard-ranelagh-foh",
    "gemcon-cathalbrugha",
    "smartcity1",
    "stephens-green",
    "treacyconsulting1",
    "treacyconsulting2",
    "treacyconsulting3",
    "dcctestdumpinghk",
    "beefcam1",
    "beefcam2",
    "beefcammobile",
    "bennett"
  ]
  begin
    total = args[:total] || Camera.count
    cameras = Camera
    cameras = cameras.where(exid: recording_cameras) if args[:paid_only].present?
    cameras.take(total.to_i).each do |camera|
      camera_url = camera.external_url.to_s
      camera_url << camera.res_url('jpg').to_s
      unless camera_url.blank?
        auth = "#{camera.cam_username}:#{camera.cam_password}"
        frequent = recording_cameras.include? camera.exid
        Sidekiq::Client.push({
          'queue' => "to_elixir",
          'class' => "ElixirWorker",
          'args' => [
            camera.exid,
            camera_url,
            auth,
            frequent
          ]
        })
      end
    end
  rescue Exception => e
    log.warn(e)
  end
end

task :add_mac_addresses do
  Sequel.connect(Evercam::Config[:database])

  require 'active_support'
  require 'active_support/core_ext'
  require 'evercam_models'

  no_onvif_support = 0

  File.open("temp/cameras_no_onvif", 'a') { |f| f.write("") }

  cameras = Camera.where(mac_address: nil)
  cameras.each do |camera|
    begin
      camera_url = camera.external_url.to_s
      camera_url << camera.res_url('jpg').to_s
      already_checked = File.foreach("temp/cameras_no_onvif").any? { |line| line.chomp == camera.exid }
      if camera_url.present? && !already_checked
        puts camera.exid
        mac_address_url = "https://media.evercam.io/v1/cameras/#{camera.exid}/macaddr"
        puts mac_address_url
        conn = Faraday.new(url: mac_address_url) do |faraday|
          faraday.adapter Faraday.default_adapter
          faraday.options.timeout = 10
          faraday.options.open_timeout = 10
        end

        response = conn.get.body
        if response == "Server internal error - 500"
          no_onvif_support += 1
          File.open("temp/cameras_no_onvif", 'a') { |f| f.write("#{camera.exid}\n") }
        else
          response = JSON.parse(response)
          camera.mac_address = response["mac_address"]
          camera.save
        end
        puts
      end
    rescue => e
      log.warn(e)
    end
  end

  puts "cameras without onvif support: #{no_onvif_support}"
end

task :add_geolocation do
  Sequel.connect(Evercam::Config[:database])

  require 'active_support'
  require 'active_support/core_ext'
  require 'evercam_models'
  require "resolv"

  Geocoder.configure(:timeout => 5, :ip_lookup => :telize)

  cameras = Camera.where(location: nil)
  cameras.each do |camera|
    begin
      puts camera.exid
      if camera.config["external_host"] =~ Resolv::IPv4::Regex
        camera.location = Geocoder.coordinates(camera.config["external_host"])
        camera.save
      end
    rescue => e
      log.warn(e)
    end
  end
end

task :update_thumbnail_url do
  require "resolv"
  require 'active_support'
  require 'active_support/core_ext'
  require 'dalli'
  require 'timeout'
  require 'evercam_models'
  require_relative 'lib/services'

  Sequel::Model.db = Sequel.connect("#{ENV['DATABASE_URL']}", max_connections: 25)
  Snapshot.db = Sequel.connect("#{ENV['SNAPSHOT_DATABASE_URL']}", max_connections: 25)

  Camera.where(is_online: false).each do |camera|
    begin
      puts camera.exid
      camera.preview = nil
      camera.thumbnail_url = nil
      camera.save

      Timeout::timeout(5) do
        last_snapshot = Snapshot.where(camera_id: camera.id).order(:created_at).last
        if last_snapshot
          filepath = "#{camera.exid}/snapshots/#{last_snapshot.created_at.to_i}.jpg"
          file = Evercam::Services.snapshot_bucket.objects[filepath]
          thumbnail_url = file.url_for(:get, {expires: 10.years.from_now, secure: true}).to_s
          camera.thumbnail_url = thumbnail_url
          camera.save
        end
      end
    rescue => e
      log.warn(e)
    end
  end
end

task :add_missing_thumbnail_url do
  require "resolv"
  require 'active_support'
  require 'active_support/core_ext'
  require 'dalli'
  require 'timeout'
  require 'evercam_models'
  require_relative 'lib/services'

  Sequel::Model.db = Sequel.connect("#{ENV['DATABASE_URL']}", max_connections: 25)
  Snapshot.db = Sequel.connect("#{ENV['SNAPSHOT_DATABASE_URL']}", max_connections: 25)

  Camera.where(is_online: false, thumbnail_url: nil).all.shuffle.each do |camera|
    begin
      puts camera.exid
      Timeout::timeout(60) do
        filepath = "#{camera.exid}/snapshots/"
        file = Evercam::Services.snapshot_bucket.objects.with_prefix(filepath).first
        if file
          thumbnail_url = file.url_for(:get, {expires: 10.years.from_now, secure: true}).to_s
          camera.thumbnail_url = thumbnail_url
          camera.save
        end
      end
    rescue => e
      log.warn(e)
    end
  end
end

task :create_cloud_recording_status do
  require 'evercam_models'

  full_schedule = {
    "Monday" => ["00:00-23:59"],
    "Tuesday" => ["00:00-23:59"],
    "Wednesday" => ["00:00-23:59"],
    "Thursday" => ["00:00-23:59"],
    "Friday" => ["00:00-23:59"],
    "Saturday" => ["00:00-23:59"],
    "Sunday" => ["00:00-23:59"]
  }

  CloudRecording.each do |cloud_recording|
    if cloud_recording.schedule == full_schedule
      if cloud_recording.frequency == 1
        cloud_recording.status = "off"
      else
        cloud_recording.status = "on"
      end
    else
      cloud_recording.status = "on-scheduled"
    end
    cloud_recording.save
  end
end

task :update_intercom_users, [:user_id, :to_id] do |_t, args|
  require 'intercom'
  Sequel::Model.db = Sequel.connect("#{ENV['DATABASE_URL']}")
  require 'evercam_models'

  VALID_EMAIL_REGEX = /\A([\w+\-].?)+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i
  if Evercam::Config.env == :production
    intercom = Intercom::Client.new(
      app_id: Evercam::Config[:intercom][:app_id],
      api_key: Evercam::Config[:intercom][:api_key]
    )
    User.where(:id => args[:user_id]...args[:to_id]).order(:id).each do |user|
      if user.email =~ VALID_EMAIL_REGEX
        puts "#{user.id}-#{user.username}-#{user.email}"
        begin
          ic_user = intercom.users.find(:email => user.email)
        rescue Intercom::ResourceNotFound
          # Ignore it
        end
        if ic_user.nil?
          # Create ic user
          begin
            intercom.users.create(
              :email => user.email,
              :user_id => user.username,
              :name => user.fullname,
              :signed_up_at => user.created_at.to_i,
              :new_session => true
            )
          rescue => error
            puts "User Create: #{error.message}"
            # Ignore it
          end
        else
          begin
            ic_user.user_id = user.username
            ic_user.email = user.email
            ic_user.name = user.fullname
            ic_user.signed_up_at = user.created_at.to_i
            ic_user.last_request_at = user.updated_at.to_i
            intercom.users.save(ic_user)
          rescue => error
            puts "User Update: #{error.message}"
            # Ignore it
          end
        end
      end
    end
  end
end

task :delete_camera_history, [:camera_id, :delete_all, :from_time, :to_time, :prior_all, :ids] do |_t, args|
  require 'aws'
  require 'active_support'
  require 'active_support/core_ext'
  require 'dalli'
  require_relative 'lib/services'
  Sequel::Model.db = Sequel.connect("#{ENV['DATABASE_URL']}", max_connections: 25)
  require 'evercam_models'
  Snapshot.db = Sequel.connect("#{ENV['SNAPSHOT_DATABASE_URL']}", max_connections: 25)

  s3 = AWS::S3.new(
    :access_key_id => Evercam::Config[:amazon][:access_key_id],
    :secret_access_key => Evercam::Config[:amazon][:secret_access_key]
  )
  snapshot_bucket = s3.buckets['evercam-camera-assets']

  puts "Start processing of camera #{args[:camera_id]}"
  if Evercam::Config.env == :production
    camera = Camera.where(:exid => args[:camera_id]).first
    cloud_recording = CloudRecording.where(camera_id: camera.id).first
    puts "Cloud Recordings: #{cloud_recording.storage_duration}" if cloud_recording.present?
    from_date = Time.new(2015, 01, 01, 0, 0, 0).utc
    to_date = Time.now.utc

    if args[:delete_all].present? && args[:delete_all].eql?("all")
      puts "Start deletion all history"
      if camera.thumbnail_url.blank?
        from_date = Time.now.utc - 1.days if camera.is_online
        latest_snap = Snapshot.where(:snapshot_id => "#{camera.id}_#{from_date.strftime("%Y%m%d%H%M%S%L")}".."#{camera.id}_#{to_date.strftime("%Y%m%d%H%M%S%L")}").order(:created_at).last
        timestamp = latest_snap.created_at.to_i

        filepath = "#{camera.exid}/snapshots/#{timestamp}.jpg"
        newpath = "#{camera.exid}/#{timestamp}.jpg"
        puts "File path path: #{newpath}"
        snapshot_bucket.objects[newpath].delete
        snapshot_bucket.objects.create(newpath, snapshot_bucket.objects[filepath].read)
      else
        filepath = URI::parse(camera.thumbnail_url).path
        filepath = filepath.gsub(camera.exid, '')
        timestamp = filepath.gsub(/[^\d]/, '').to_i

        filepath = "#{camera.exid}/snapshots/#{timestamp}.jpg"
        newpath = "#{camera.exid}/#{timestamp}.jpg"
        snapshot_bucket.objects[newpath].delete
        snapshot_bucket.objects.create(newpath, snapshot_bucket.objects[filepath].read)
      end
      Snapshot.where(:camera_id => camera.id).delete
      snapshot_bucket.with_prefix("#{camera.exid}/snapshots/").delete_all
      puts "Delete all history for camera: #{camera.name}"
      if camera.thumbnail_url.blank?
        filepath = "#{camera.exid}/snapshots/#{timestamp}.jpg"
        newpath = "#{camera.exid}/#{timestamp}.jpg"
        snapshot_bucket.objects.create(filepath, snapshot_bucket.objects[newpath].read)
        snapshot_bucket.objects[newpath].delete
        file = snapshot_bucket.objects[filepath]
        camera.thumbnail_url = file.url_for(:get, {expires: 10.years.from_now, secure: true}).to_s
        camera.save
      end
      Evercam::Services.dalli_cache.flush_all
    elsif args[:delete_all].present? && args[:delete_all].eql?("all-camera")
      puts "Start deletion all history and delete camera"
      ids = args[:ids].split(",").inject([]) { |list, entry| list << entry.strip }
      Camera.where(exid: ids).each do |cam|
        snapshot_bucket.with_prefix("#{cam.exid}/").delete
        camera_name = cam.name
        cam.delete
        puts "Delete all history and also delete camera: #{camera_name}"
      end
      Evercam::Services.dalli_cache.flush_all
      puts "Cameras deleted along with history."
    elsif args[:prior_all].present?
      puts "Start deletion prior to all"
      first_snap = Snapshot.where(:snapshot_id => "#{camera.id}_#{from_date.strftime("%Y%m%d%H%M%S%L")}".."#{camera.id}_#{to_date.strftime("%Y%m%d%H%M%S%L")}").order(:created_at).first
      latest_snap = Snapshot.where(:snapshot_id => "#{camera.id}_#{from_date.strftime("%Y%m%d%H%M%S%L")}".."#{camera.id}_#{to_date.strftime("%Y%m%d%H%M%S%L")}").order(:created_at).last
      to = latest_snap.created_at - args[:prior_all].to_i.days
      puts "From: #{first_snap.created_at}"
      puts "To: #{to}"
      snapshots = Snapshot.where(:snapshot_id => "#{camera.id}_#{first_snap.created_at.strftime("%Y%m%d%H%M%S%L")}"..."#{camera.id}_#{to.strftime("%Y%m%d%H%M%S%L")}").select
      puts "Total snapshots: #{snapshots.count}"

      snapshots.each do |snapshot|
        filepath = "#{camera.exid}/snapshots/#{snapshot.created_at.to_i}.jpg"
        snapshot_bucket.objects[filepath].delete
        snapshot.delete
        puts "Delete snapshot: #{filepath}"
      end
      Evercam::Services.dalli_cache.flush_all
      puts "Snapshots deleted"
    elsif args[:from_time].present? && args[:to_time].present?
      puts "Start deletion according to from-date and to-date"
      from_time = Time.parse(args[:from_time]).utc
      to_time = Time.parse(args[:to_time]).utc
      puts "From Time: #{from_time.to_s}"
      puts "To Time: #{to_time.to_s}"
      snapshots = Snapshot.where(:snapshot_id => "#{camera.id}_#{from_time.strftime("%Y%m%d%H%M%S%L")}"..."#{camera.id}_#{to_time.strftime("%Y%m%d%H%M%S%L")}").select
      puts "Total snapshots: #{snapshots.count}"

      snapshots.each do |snapshot|
        filepath = "#{camera.exid}/snapshots/#{snapshot.created_at.to_i}.jpg"
        snapshot_bucket.objects[filepath].delete
        snapshot.delete
        puts "Delete snapshot: #{filepath}"
      end
      Evercam::Services.dalli_cache.flush_all
      puts "Snapshots deleted"
    else
      puts "Start deletion according to camera-id"
      first_snap = Snapshot.where(:snapshot_id => "#{camera.id}_#{from_date.strftime("%Y%m%d%H%M%S%L")}".."#{camera.id}_#{to_date.strftime("%Y%m%d%H%M%S%L")}").order(:created_at).first
      latest_snap = Snapshot.where(:snapshot_id => "#{camera.id}_#{from_date.strftime("%Y%m%d%H%M%S%L")}".."#{camera.id}_#{to_date.strftime("%Y%m%d%H%M%S%L")}").order(:created_at).last
      to = latest_snap.created_at - cloud_recording.storage_duration.days
      puts "From: #{first_snap.created_at}"
      puts "To: #{to}"
      snapshots = Snapshot.where(:snapshot_id => "#{camera.id}_#{first_snap.created_at.strftime("%Y%m%d%H%M%S%L")}"..."#{camera.id}_#{to.strftime("%Y%m%d%H%M%S%L")}").select
      puts "Total snapshots: #{snapshots.count}"

      snapshots.each do |snapshot|
        filepath = "#{camera.exid}/snapshots/#{snapshot.created_at.to_i}.jpg"
        snapshot_bucket.objects[filepath].delete
        snapshot.delete
        puts "Delete snapshot: #{filepath}"
      end
      Evercam::Services.dalli_cache.flush_all
      puts "Snapshots deleted"
    end
  end
end