# Flowkit v21.12-s019_1
################################################################################
# This file contains 'create_flow_step' content for steps which are required
# in an implementation flow, but whose contents are specific.  Review  all
# <PLACEHOLDER> content and replace with commands and options more appropriate
# for the design being implemented. Any new flowstep definitions should be done
# using the 'flow_config.tcl' file.
################################################################################

##############################################################################
# STEP set_dont_use
##############################################################################
create_flow_step -name set_dont_use -owner design {
  #- disable base_cell usage during optimization
  <%? {dont_use_cells} return "foreach base_cell_name [list [get_flow_config dont_use_cells]] {set_db \[get_db base_cells \$base_cell_name\] .dont_use true}" %>
}

##############################################################################
# STEP init_floorplan
##############################################################################
create_flow_step -name init_floorplan -owner design {
#- initialize floorplan object using DEF and/or floorplan files
<%? {init_floorplan_file} return "read_floorplan [get_flow_config init_floorplan_file]" %>
<%? {init_def_files} return "foreach def_file [list [get_flow_config init_def_files]] { read_def \$def_file }" %>

#- finish floorplan with auto-blockage insertion
finish_floorplan  -fill_place_blockage soft 20.0
} -check {
foreach file [get_flow_config -quiet init_floorplan_file] {
  check "[file exists $file] && [file readable $file]" "The floorplan file: $file was not found or is not readable."
}
foreach file [get_flow_config -quiet init_def_files] {
  check "[file exists $file] && [file readable $file]" "The def file: $file was not found or is not readable."
}
}
if {[get_feature clock_flexible_htree]} {
  
  ############################################################################
  # STEP add_clock_htree_spec
  ############################################################################
  create_flow_step -name add_clock_htree_spec -owner design {
    #- specify parameters for building H-tree structure
    create_flexible_htree       << PLACEHOLDER: CREATE FLEXIBLE HTREE OPTIONS >>
  }
}

##############################################################################
# STEP add_clock_route_types
##############################################################################
create_flow_step -name add_clock_route_types -owner design {
  #- define route_types and/or route_rules
  create_route_type -name cts_top   < PLACEHOLDER: CLOCK TOP ROUTE RULE >
  create_route_type -name cts_trunk < PLACEHOLDER: CLOCK TRUNK ROUTE RULE >
  create_route_type -name cts_leaf  < PLACEHOLDER: CLOCK LEAF ROUTE RULE >
  
  set_db cts_route_type_top  cts_top
  set_db cts_route_type_trunk cts_trunk
  set_db cts_route_type_leaf  cts_leaf
}
