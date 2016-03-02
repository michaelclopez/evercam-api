Sequel.migration do
  up do
    alter_table(:users) do
      add_column :vat_number, :text, null: true
    end
  end

  down do
    alter_table(:users) do
      drop_column :vat_number
    end
  end
end
