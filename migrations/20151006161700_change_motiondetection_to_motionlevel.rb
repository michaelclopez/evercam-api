Sequel.migration do
  up do
    alter_table(:snapshots) do
      rename_column :motiondetection, :motionlevel
    end
  end

  down do
    alter_table(:snapshots) do
      rename_column :motionlevel, :motiondetection
    end
  end
end
