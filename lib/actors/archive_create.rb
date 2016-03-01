module Evercam
  module Actors
    class ArchiveCreate < Mutations::Command

      required do
        string :id
        string :title
        integer :from_date
        integer :to_date
        string :requested_by
      end

      optional do
        boolean :embed_time
        boolean :public
        string :timezone
      end

      def validate
        off_set = Time.now.in_time_zone(timezone).strftime("%:z")
        from = Time.at(from_date).utc
        to = Time.at(to_date).utc
        clip_from_date = Time.new(from.year, from.month, from.day, from.hour, from.min, from.sec, off_set).utc
        clip_to_date = Time.new(to.year, to.month, to.day, to.hour, to.min, to.sec, off_set).utc

        if Time.now.utc <= clip_from_date
          add_error(:from_date, :valid, 'From date cannot be greater than current time.')
        end
        if Time.now.utc <= clip_to_date
          add_error(:to_date, :valid, 'To date cannot be greater than current time.')
        end
        if clip_to_date < clip_from_date
          add_error(:to_date, :valid, 'To date cannot be less than from date.')
        end
        if clip_from_date.eql?(clip_to_date)
          add_error(:to_date, :valid, 'To date and from date cannot be same.')
        end
        hours = ((clip_to_date - clip_from_date) / 1.hour).round
        if hours > 2
          add_error(:to_date, :valid, "Clip duration cannot be greater than 2 hours.")
        end
      end

      def execute
        camera = Camera.by_exid!(inputs[:id])
        raise Evercam::ConflictError.new("A camera with the id '#{inputs[:id]}' does not exist.",
                                           "camera_not_exist_error", inputs[:id]) if camera.nil?

        user = User.by_login(inputs[:requested_by])
        raise NotFoundError.new("Unable to locate a user for '#{inputs[:requested_by]}'.",
                                "user_not_found_error", inputs[:requested_by]) if user.nil?

        clip_exid = title.downcase.gsub(' ','')
        chars = [('a'..'z'), (0..9)].flat_map { |i| i.to_a }
        random_string = (0...3).map { chars[rand(chars.length)] }.join
        clip_exid = "#{clip_exid[0..5]}-#{random_string}"
        off_set = Time.now.in_time_zone(camera.timezone.zone).strftime("%:z")
        from = Time.at(from_date).utc
        to = Time.at(to_date).utc
        clip_from_date = Time.new(from.year, from.month, from.day, from.hour, from.min, from.sec, off_set).utc
        clip_to_date = Time.new(to.year, to.month, to.day, to.hour, to.min, to.sec, off_set).utc

        archive = Archive.new(
          camera: camera,
          exid: clip_exid,
          title: title,
          from_date: clip_from_date,
          to_date: clip_to_date,
          status: Archive::PENDING,
          user: user
        )

        archive.embed_time = embed_time if embed_time
        archive.public = public if public
        Archive.db.transaction do
          archive.save
        end
      end
    end
  end
end