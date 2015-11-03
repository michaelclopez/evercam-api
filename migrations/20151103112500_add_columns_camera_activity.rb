Sequel.migration do
  up do
    alter_table(:camera_activities) do
      add_column :camera_exid, :text
      add_column :name, :text
    end
  end

  down do
    alter_table(:camera_activities) do
      drop_column :camera_exid
      drop_column :name
    end
  end
end
