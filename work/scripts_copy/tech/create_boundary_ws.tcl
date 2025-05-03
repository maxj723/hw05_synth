##############################################################################
# STEP create_boundary_ws
##############################################################################
create_flow_step -name create_boundary_ws -skip_db -skip_metric -owner intel {
  
  floorplan_set_snap_rule -for PLK -grid MG -force
  create_place_blockage -rects [get_computed_shapes -output rect [get_db designs .boundary] ANDNOT [get_computed_shapes [get_db designs .boundary] SIZEX -$vars(INTEL_WS_X) SIZEY -$vars(INTEL_WS_Y)]] -name boundary_ws -type hard
  
}
