Sequel.migration do
  up do
    alter_table(:motion_detections) do
      set_column_allow_null :frequency
      set_column_allow_null :minPosition
      set_column_allow_null :step
      set_column_allow_null :min
      set_column_allow_null :threshold
    end
  end
end
