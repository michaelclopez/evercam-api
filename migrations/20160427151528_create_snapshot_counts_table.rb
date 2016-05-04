Sequel.migration do
  up do
    create_table(:snapshot_counts) do
      primary_key :count_id, type: :text, name: :count_id
      column :count, :integer
    end
  end

  down do
    drop_table(:snapshot_counts)
  end
end
