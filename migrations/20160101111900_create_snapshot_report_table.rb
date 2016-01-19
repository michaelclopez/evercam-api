Sequel.migration do
  up do
    create_table(:snapshot_reports) do
      primary_key :id
      foreign_key :camera_id, :cameras, null: false
      column :created_at, :timestamptz, null: false
      column :report_date, :timestamptz, null: false
    end
  end

  down do
    drop_table(:snapshot_reports)
  end
end
