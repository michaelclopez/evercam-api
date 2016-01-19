Sequel.migration do
  up do
    alter_table(:snapshot_reports) do
      add_column :snapshot_count, :integer, null: false
    end
  end

  down do
  	alter_table(:snapshot_reports) do
  		drop_column :snapshot_count
  	end
  end
end
