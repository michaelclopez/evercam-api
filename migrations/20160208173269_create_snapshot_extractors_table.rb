Sequel.migration do
  up do
    create_table(:snapshot_extractors) do
      primary_key :id
      foreign_key :camera_id, :cameras, null: false
      column :from_date, :timestamptz, null: false
      column :to_date, :timestamptz, null: false
      column :interval, :integer, null: false
      column :schedule, :json, null: false
    end
  end

  down do
    drop_table(:snapshot_extractors)
  end
end
