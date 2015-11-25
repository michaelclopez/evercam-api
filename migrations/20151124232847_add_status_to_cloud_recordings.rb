Sequel.migration do
  up do
    alter_table(:cloud_recordings) do
      add_column :status, :text
    end
  end

  down do
    alter_table(:cloud_recordings) do
      drop_column :status
    end
  end
end
