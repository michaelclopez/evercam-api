Sequel.migration do
  up do
    alter_table(:snapshot_extractors) do
      add_column :notes, :text, null: true
      add_column :created_at, :timestamptz, null: false
      add_column :update_at, :timestamptz, null: true
    end
  end

  down do
    alter_table(:snapshot_extractors) do
      drop_column :notes
      drop_column :created_at
      drop_column :update_at
    end
  end
end