Sequel.migration do
  up do
    alter_table(:users) do
      add_column :last_login_at, :timestamptz, null: true
    end
  end

  down do
    alter_table(:users) do
      drop_column :last_login_at
    end
  end
end
