##############################################################################
# STEP create_row
##############################################################################
create_flow_step -name create_row -skip_db -skip_metric -owner intel {

delete_row -all

set design_boundary [get_db current_design .boundary]
set design_boundary_boxes [get_computed_shapes [get_db current_design .boundary]]
set_db floorplan_initial_all_compatible_core_site_rows true

 if {[llength $design_boundary_boxes] == 1 } {
        set rectangular 1
 } elseif {[llength $design_boundary_boxes] > 1 } {
        set rectangular 0
 }

if {$rectangular == 1}  {
        create_row -site $vars(INTEL_STDCELL_TILE) -flip_first_row
        create_row -site $vars(INTEL_STDCELL_CORE2H_TILE) -no_flip_rows  -area [get_computed_shapes [get_db designs .boundary.bbox] SIZEY -0.54]
	create_row -site $vars(INTEL_STDCELL_BONUS_GATEARRAY_TILE) -flip_first_row
} else {
	set dbboxes [get_computed_shapes [get_db designs .boundary] SIZEY -0.54]
	create_row -site $vars(INTEL_STDCELL_TILE) -flip_first_row
        foreach box $dbboxes {
		create_row -site $vars(INTEL_STDCELL_CORE2H_TILE) -no_flip_rows -area "{$box}"
	}
	create_row -site $vars(INTEL_STDCELL_BONUS_GATEARRAY_TILE) -flip_first_row
}
}
