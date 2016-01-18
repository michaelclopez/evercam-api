Sequel.migration do
  up do
    alter_table(:cameras) do
      drop_column :preview
    end
  end

  down do
    alter_table(:cameras) do
      add_coloumn :preview, File
    end
  end
end
