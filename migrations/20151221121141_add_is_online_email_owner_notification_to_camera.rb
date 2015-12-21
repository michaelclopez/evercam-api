Sequel.migration do
  up do
    alter_table(:cameras) do
      add_column :is_online_email_owner_notification, :boolean, null: false, default: false
    end
  end

  down do
    alter_table(:cameras) do
      drop_column :is_online_email_owner_notification
    end
  end
end
