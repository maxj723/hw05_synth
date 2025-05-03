##############################################################################                                                                                            
# STEP create_boundary_ws
##############################################################################
create_flow_step -name create_boundary_si_blockage -skip_db -skip_metric -owner intel {
global vars
global env

set wd 0.080
set ht 0.080

set blkg_layer "m1 m2 m3 m4 m5 m6 m7 m8"   

set top_boxes [get_computed_shapes [get_db designs .boundary] ANDNOT [get_computed_shapes [get_db designs .boundary] SIZEX -$wd SIZEY -$ht]]

create_route_blockage -layers $blkg_layer -rects $top_boxes -name Route_blkg_boundry

}
