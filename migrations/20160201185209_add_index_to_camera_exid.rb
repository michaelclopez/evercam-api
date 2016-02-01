Sequel.migration do
  up do
    add_index(:cameras, [:exid], unique: true)
  end

  down do
    drop_index(:cameras, [:exid])
  end
end
