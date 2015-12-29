Sequel.migration do
  up do
    alter_table(:cloud_recordings) do
      add_index [:camera_id], unique: true
    end
  end
end
