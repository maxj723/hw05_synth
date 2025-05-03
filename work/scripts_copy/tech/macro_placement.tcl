##############################################################################
# STEP macro_placement
##############################################################################
create_flow_step -name macro_placement -skip_db -skip_metric -owner intel {

##############################################################################
# This script will auto-place macros in the design
# Can be used during early exploration stage
# List of procs used by the script
# 1. P_msg_info

# Check: Are there any macro cells?
if {[llength [get_db insts -if .is_macro ]] == 0} {
  P_msg_info "There are no macro cells in this design"
  return
} else {
    puts "Snap the macro to User defined grid"
    set_preference ConstraintUserYGrid $vars(INTEL_MD_GRID_Y)
    set_preference ConstraintUserXGrid $vars(INTEL_MD_GRID_X)
    floorplan_set_snap_rule -for BLK -grid UG -force
    snap_floorplan -macro_pin
}

# Check: Are thre any macro cells not placed?
if {[llength [get_db [get_db insts -if .is_macro ] -if .place_status=="unplaced" ]] == 0} {
  P_msg_info "All macro cells are already placed"
  foreach inst  [get_db insts -if .is_macro ] {
    set_db $inst .place_status fixed
  }
  return
}

# Fix the locations of already placed macro cells.
P_msg_info "If some macros already placed, they are marked fixed"
foreach inst  [get_db [get_db insts -if .is_macro ] -if .place_status=="placed" ] {
    set_db $inst .place_status fixed
}

# Restrict macro placement orientation.  We do not allow 90 degree rotation
P_msg_info "Restricting macro placement orientation to R0 R180 MX MY"
foreach inst  [get_db [get_db insts -if .is_macro ] -if .base_cell.symmetry=="any" ] {
    set_db $inst .base_cell.symmetry xy
}

# Restrict macro placement to modular grid.  So that macro/APR boundaries are DRC clean.
P_msg_info "Restricting macros placement to be on modular grid ( $vars(INTEL_MD_GRID_X) , $vars(INTEL_MD_GRID_Y) )"
set_preference ConstraintUserYGrid $vars(INTEL_MD_GRID_Y)
set_preference ConstraintUserXGrid $vars(INTEL_MD_GRID_X)
floorplan_set_snap_rule -for BLK -grid UG -force

# Run "create_fp_placement" to place macros
P_msg_info "Auto placing macro cells"
P_msg_info "Running: planDesign with options effort high useGuideBoundary fence boundary Place false "

set_db plan_design_effort high ; set_db plan_design_use_guide_boundary fence ; set_db plan_design_incremental false ; set_db plan_design_boundary_place false ; set_db plan_design_fix_placed_macros true 
#place_design -concurrent_macros
plan_design
#place_blocks_refine

foreach inst  [get_db insts -if .is_macro ] {
  set_db $inst .place_status fixed
}

P_msg_info "Placement results are only preliminary. It is recommended to adjust placement of macros to desired locations."
P_msg_info "Please check results at this stage and adjust the macro placement.  Power domains and other placement may not be maintained and may need to be adjusted."
P_msg_info "USER NEEDS CONFIRM THAT PLACEMENT IS GOOD BEFORE RUNNING THE REST OF THE FLOW"
P_msg_info "Placement can be saved to script to use in future where you do not have to rerun if you write_macro_placement ./scripts/macro_placement.tcl.  This will put a placement file in the scripts directory that will be called instead of the placement script."
#
# Once macro placements are determined, create a design specific file ./scripts/macro_placement.tcl
# to override this auto macro placement in the default flow.
#
# You can write out macro placement with
# write_macro_placment ./scripts/macro_placement.tcl
#
# A typical format for this file would look like this
#
#placeInstance <macro-name> {71.658 120.960} R0 fixed
#

}
