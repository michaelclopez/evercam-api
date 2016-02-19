Sequel.migration do
  up do
    create_table(:licences) do
      primary_key :id
      foreign_key :user_id, :users, null: false
      column :description, :text, null: false
      column :total_cameras, :integer, null: false
      column :storage, :integer, null: false
      column :amount, :double
      column :paid, :boolean, null: false, default: false
      column :vat, :boolean, null: false, default: false
      column :vat_number, :integer
      column :start_date, :timestamptz, null: false
      column :end_date, :timestamptz, null: false
      column :created_at, :timestamptz, null: false
    end
  end

  down do
    drop_table(:licences)
  end
end
