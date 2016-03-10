Sequel.migration do
  up do
    alter_table(:users) do
      add_column :payment_method, :integer, null: true, default: 0
    end
  end

  down do
    alter_table(:users) do
      drop_column :payment_method
    end
  end
end
