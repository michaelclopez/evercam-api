Sequel.migration do
  change do
    alter_table(:users) do
      drop_column :is_admin
    end
  end
end
