Sequel.migration do

  up do
    alter_table(:snapshot_extractors) do
      add_column :status, :integer, null: false, default: 0
    end
  end

  down do
    alter_table(:snapshot_extractors) do
      drop_column :status
    end
  end
end
