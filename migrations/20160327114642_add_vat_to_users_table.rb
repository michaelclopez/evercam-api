Sequel.migration do
  up do
    alter_table(:users) do
      add_column :vat, :text, null: true
    end
  end

  down do
    alter_table(:users) do
      drop_column :vat
    end
  end
end
