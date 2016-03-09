Sequel.migration do
  up do
    alter_table(:licences) do
      add_column :subscription_id, :text, null: true
      add_column :auto_renew, :boolean, null: false, default: false
      add_column :auto_renew_at, :timestamptz, null: true
    end
  end

  down do
    alter_table(:licences) do
      drop_column :notes
      drop_column :created_at
      drop_column :update_at
    end
  end
end
