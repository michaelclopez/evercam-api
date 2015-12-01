Sequel.migration do
  up do
    alter_table(:snapshots) do
      set_column_allow_null :motionlevel
    end
  end
end
