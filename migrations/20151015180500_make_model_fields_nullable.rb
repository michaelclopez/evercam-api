Sequel.migration do
  up do
    alter_table(:vendor_models) do
      set_column_allow_null :resolution
      set_column_allow_null :official_url
      set_column_allow_null :audio_url
      set_column_allow_null :more_info
      set_column_allow_null :poe
      set_column_allow_null :wifi
      set_column_allow_null :onvif
      set_column_allow_null :psia
      set_column_allow_null :ptz
      set_column_allow_null :infrared
      set_column_allow_null :varifocal
      set_column_allow_null :sd_card
      set_column_allow_null :upnp
      set_column_allow_null :audio_io
      set_column_allow_null :discontinued
    end
  end
end
