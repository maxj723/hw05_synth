#This flow step is to replace data cells on clock path with clock cells from the library
#This workaround is provided by Cadence to overcome the default functionality of Genus mapper.
#Genus mapper by default maps data cells on clock path. 
create_flow_step -name remap_data_cells -skip_db -skip_metric -owner cadence {
  
  set_db ignore_clock_path_check true
  set_db [get_db clocks *] .clock_library_cells [get_db lib_cells *b0mc*]
  remap_to_dedicated_clock_library -clocks [get_db clocks *] -effort high
}
