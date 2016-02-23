Sequel.migration do
  up do
    alter_table(:licences) do
      add_column :cancel_licence, :boolean, null: false, default: false
    end
  end

  down do
    alter_table(:licences) do
      drop_column :cancel_licence
    end
  end
end