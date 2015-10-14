Sequel.migration do
  up do
    create_table(:motion_detection) do
      primary_key :id
      foreign_key :camera_id, :cameras, null: false
      column :frequency, :integer, null: false
      column :minPosition, :integer, null: false # see EvercamMedia.MotionDetection.Lib.compare for more details
      column :step, :integer, null: false
      column :min, :integer, null: false
      column :schedule, :json
    end
  end

  down do
    drop_table(:motion_detection)
  end
end
