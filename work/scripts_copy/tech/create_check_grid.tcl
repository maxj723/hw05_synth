##############################################################################
# STEP create_check_grid
##############################################################################
create_flow_step -name create_check_grid -skip_db -skip_metric -owner intel {

  # PolyGrid and Diffgrid check
  set step 0.090
  set width 0.031
  set start 0.0745
  set stop 0.0745
  P_create_diffcheck_grid $start $width $step $stop
  
}
