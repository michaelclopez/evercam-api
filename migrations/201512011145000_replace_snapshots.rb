Sequel.migration do
  up do
    rename_table :snapshots, :snapshots_old

    create_table(:snapshots) do
      primary_key :snapshot_id, type: :text, name: :snapshot_id
      foreign_key :camera_id, :cameras, null: false
      column :created_at, :timestamptz, null: false
      column :notes, :text
      column :is_public, :boolean, default: false
      column :motionlevel, :integer, null: false
    end
  end

  down do
    drop_table(:snapshots)
    rename_table :snapshots_old, :snapshots
  end
end
