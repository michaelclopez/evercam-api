Sequel.migration do
  up do
    alter_table(:snapshots) do
      add_column :snapshot_id, :text, null: true
    end
  end

  down do
    alter_table(:snapshots) do
      drop_column :snapshot_id
    end
  end
end
