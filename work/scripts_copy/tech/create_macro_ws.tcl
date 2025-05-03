##############################################################################
# STEP create_macro_ws
##############################################################################
create_flow_step -name create_macro_ws -skip_db -skip_metric -owner intel {

  #R0 orient -halo_deltas {left bottom right top}
  create_place_halo -all_macros  -snap_to_site -halo_deltas [list $vars(INTEL_WS_X) $vars(INTEL_WS_Y) $vars(INTEL_WS_X) $vars(INTEL_WS_Y) ] 
  create_place_halo -all_io_pads -snap_to_site -halo_deltas [list $vars(INTEL_WS_X) $vars(INTEL_WS_Y) $vars(INTEL_WS_X) $vars(INTEL_WS_Y) ] 

}
