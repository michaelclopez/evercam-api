Sequel.migration do
  up do
    alter_table(:motion_detections) do
      add_column :enabled, :boolean, default: false
      add_column :alert_email, :boolean, default: false
      add_column :alert_interval_min, :integer
      add_column :sensitivity, :integer
      add_column :x1, :integer
      add_column :y1, :integer
      add_column :x2, :integer
      add_column :y2, :integer
      add_column :emails, :text, array: true
    end
  end

  down do
    alter_table(:motion_detections) do
      drop_column :enabled
      drop_column :alert_email
      drop_column :alert_interval_min
      drop_column :sensitivity
      drop_column :x1
      drop_column :y1
      drop_column :x2
      drop_column :y2
      drop_column :emails
    end
  end
end
