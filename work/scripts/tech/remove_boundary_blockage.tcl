##############################################################################
# STEP remove_boundary_blockage
##############################################################################
create_flow_step -name remove_boundary_blockage -skip_db -skip_metric -owner intel {

  delete_route_blockages -name route_macro_blockage*
  delete_route_blockages -name Route_blkg_boundry* 
  
}
