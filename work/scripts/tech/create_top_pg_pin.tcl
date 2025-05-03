##############################################################################
# STEP create_top_pg_pin
##############################################################################
create_flow_step -name create_top_pg_pin -skip_db -skip_metric -owner intel {

   set nets "[get_flow_config init_power_nets] [get_flow_config init_ground_nets]"
   deselect_obj -all
   foreach net $nets {
    set top_layers "$vars(INTEL_TOP_PG_PIN_LAYER)"
    foreach layer $top_layers {
      
      select_routes -layer $layer -shapes stripe -nets $net
      set layer_net_bboxes [get_db [get_db selected] .polygon.bbox]
      deselect_obj [get_db selected]
      if { [llength $layer_net_bboxes] > 0} {
        foreach layer_net_bbox $layer_net_bboxes {
          set llx [lindex $layer_net_bbox 0]
          set lly [lindex $layer_net_bbox 1]
          set urx [lindex $layer_net_bbox 2]
          set ury [lindex $layer_net_bbox 3]
          create_pg_pin -name $net -geometry  $layer $llx $lly $urx $ury
        }
      }
    }
  }
}
