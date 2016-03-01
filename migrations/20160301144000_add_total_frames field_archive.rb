Sequel.migration do
  up do
    alter_table(:archives) do
      add_column :frames, :integer, null: true, default: 0
    end
  end

  down do
    alter_table(:archives) do
      drop_column :frames
    end
  end
end
