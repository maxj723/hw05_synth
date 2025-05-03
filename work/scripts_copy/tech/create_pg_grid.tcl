##############################################################################
# STEP create_pg_grid
##############################################################################
create_flow_step -name create_pg_grid -skip_db -skip_metric -owner intel {
global vars
global env

set_db generate_special_via_partial_overlap_threshold 0
set_db generate_special_via_opt_cross_via true
set_db generate_special_via_enable_check_drc  true
set_db generate_special_via_ignore_drc false
set_db generate_special_via_allow_wire_shape_change false
set_db add_stripes_remove_floating_stripe_over_block false
set_db add_stripes_ignore_drc true
set_db add_stripes_use_exact_spacing true
set_db add_stripes_remove_floating_stripe_over_block 1
set_db add_stripes_skip_via_on_pin {}

set upf_available [string is space [get_flow_config -quiet init_power_intent_files 1801]]
if {!($upf_available)} {
     eval_legacy "set pwStripeStapling    1"
   set_db generate_special_via_allow_wire_shape_change false
   set_db generate_special_via_enable_check_drc  false
   ##CCR raised for crash##
} else {
   eval_legacy "set pwStripeStapling 3 "
}
   delete_all_power_preroutes

if {! [file exists $env(WORK_DIR)/scripts]} { mkdir $env(WORK_DIR)/scripts} 
set OUTPUT_PG_GRID_FILE $env(WORK_DIR)/scripts/pg_grid.tcl

create_pg_grid -out_command_file $OUTPUT_PG_GRID_FILE -max_pg_layer [get_db [get_db layers [get_flow_config routing_layers pg   ]]  .route_index] 

source $OUTPUT_PG_GRID_FILE

P_delete_SacrificalM1_for_via1_onFollowPin

# Inserting M1 Followpins on M2 stripes

set upf_available [string is space [get_flow_config -quiet init_power_intent_files 1801]]
if {!($upf_available)} {
  set pg_net_list ""
  foreach pd [get_db power_domains .name] {
    set pg_nets ""
    lappend pg_nets [get_db [get_db power_domains $pd ] .primary_power_net.name]
    lappend pg_nets [get_db [get_db power_domains $pd ] .primary_ground_net.name]
    foreach net $pg_nets {
      if {[lsearch -exact $pg_net_list $net] == -1} {	
        select_routes -layer m2 -shapes stripe  -nets   $net  
        set m2_net_bboxes [get_db [get_db selected] .polygon.bbox]
        deselect_obj [get_db selected]
                if { [llength $m2_net_bboxes] > 0} {
                        foreach m2_net_bbox $m2_net_bboxes {
                                if { $m2_net_bbox != "" } {
                                    create_shape -layer m1 -net $net -rect $m2_net_bbox -shape stripe
                                }
                        }
               }
        lappend pg_net_list $net
      }
    } 
  }
} else {
  foreach net [get_db [get_db pg_nets -if {.is_power || .is_ground } ] .name] {
    select_routes -layer m2 -shapes stripe  -nets $net
    set m2_net_bboxes [get_db [get_db selected] .polygon.bbox]
    deselect_obj [get_db selected]
                if { [llength $m2_net_bboxes] > 0} {
                        foreach m2_net_bbox $m2_net_bboxes {
                                if { $m2_net_bbox != "" } {
                                    create_shape -layer m1 -net $net -rect $m2_net_bbox -shape stripe
                           }
                    }
             }
       }
}
}
