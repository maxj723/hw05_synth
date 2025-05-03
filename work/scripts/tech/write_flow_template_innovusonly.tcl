write_flow_template \
  -dir $env(PWD)/scripts \
  -type stylus \
  -tools {innovus} \
  -enable_feature { opt_early_cts } \
  -optional_feature { \
  clock_flexible_htree     \
  opt_eco                  \
  opt_signoff              \
  report_defer             \
  report_inline            \
  report_none              \
  route_track_opt          \
  } \
 -tech_steps  " \
  $env(TECH_MODULE_DIR)/add_tap_cells.tcl \
  $env(TECH_MODULE_DIR)/pre_place_bonus_fib.tcl \
  $env(TECH_MODULE_DIR)/pre_place_fiducial.tcl \
  $env(TECH_MODULE_DIR)/check_floorplan.tcl \
  $env(TECH_MODULE_DIR)/global_net_connect.tcl \
  $env(TECH_MODULE_DIR)/create_boundary_ws.tcl \
  $env(TECH_MODULE_DIR)/create_boundary_si_blockage.tcl \
  $env(TECH_MODULE_DIR)/create_check_grid.tcl \
  $env(TECH_MODULE_DIR)/init_innovus_intel.tcl \
  $env(TECH_MODULE_DIR)/create_macro_ws.tcl \
  $env(TECH_MODULE_DIR)/insert_antenna_diodes_on_input.tcl \
  $env(TECH_MODULE_DIR)/create_pg_grid.tcl \
  $env(TECH_MODULE_DIR)/create_pg_grid_procs.tcl \
  $env(TECH_MODULE_DIR)/create_rectilinear_routing_blockage.tcl \
  $env(TECH_MODULE_DIR)/create_row.tcl \
  $env(TECH_MODULE_DIR)/add_tracks.tcl \
  $env(TECH_MODULE_DIR)/macro_placement.tcl \
  $env(TECH_MODULE_DIR)/create_top_pg_pin.tcl \
  $env(TECH_MODULE_DIR)/ndr_definition.tcl \
  $env(TECH_MODULE_DIR)/write_oas.tcl \
  $env(TECH_MODULE_DIR)/extend_tgoxid.tcl \
  $env(TECH_MODULE_DIR)/remove_boundary_blockage.tcl \
  $env(TECH_MODULE_DIR)/init_genus_intel.tcl \
  $env(TECH_MODULE_DIR)/init_tempus_intel.tcl \
  $env(TECH_MODULE_DIR)/pre_db.tcl \
  $env(TECH_MODULE_DIR)/remap_data_cells.tcl \
  $env(TECH_MODULE_DIR)/edit_flow_sequence.tcl \
  "
