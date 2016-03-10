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
      drop_column :subscription_id
      drop_column :auto_renew
      drop_column :auto_renew_at
    end
  end
end
