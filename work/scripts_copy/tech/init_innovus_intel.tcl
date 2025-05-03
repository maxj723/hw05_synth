##############################################################################
# STEP init_innovus_intel
##############################################################################
create_flow_step -name init_innovus_intel -skip_metric {

  #Source procedures used by tech modules
  foreach tclProc [glob  $env(TECH_MODULE_DIR)/procs/*tcl] {
    source -quiet $tclProc
  }

  # DKG technology configuration
  source -quiet $env(TECH_MODULE_DIR)/tech_config.tcl 
  source -quiet $env(TECH_MODULE_DIR)/default_settings.tcl
  source -quiet $env(TECH_MODULE_DIR)/set_pg_grid_config.tcl

  # Timing attributes  [get_db -category timing && delaycalc]
  #-----------------------------------------------------------------------------

  # To enable freq based max_cap scaling
  set_db timing_report_drv_per_frequency true

  set_db timing_report_enable_verbose_ssta_mode true
  set_db timing_report_fields { instance arc cell delay delay_mean delay_sigma user_derate socv_derate total_derate arrival arrival_mean arrival_sigma  required }
  set_db timing_enable_spatial_derate_mode true
  set_db timing_spatial_derate_distance_mode chip_size

  if {$vars(INTEL_LIB_TYPE) == "7t108"} {
    set_db -quiet [get_db base_cells] .voltage_threshold_group ""
    set_db [get_db base_cells b15???????h* -if !.is_black_box] .voltage_threshold_group LVT
    set_db [get_db base_cells b15???????m* -if !.is_black_box] .voltage_threshold_group LPLVT
    set_db [get_db base_cells b15???????n* -if !.is_black_box] .voltage_threshold_group NOM
    set_db [get_db base_cells b15???????r* -if !.is_black_box] .voltage_threshold_group ULP
    set_db [get_db base_cells b15???????s* -if !.is_black_box] .voltage_threshold_group ULVT
    set_db [get_db base_cells b15???????l* -if !.is_black_box] .voltage_threshold_group LP
    set_db [get_db base_cells b15???????q* -if !.is_black_box] .voltage_threshold_group HP
  }
  if {$vars(INTEL_LIB_TYPE) == "7t144"} {
    set_db -quiet [get_db base_cells] .voltage_threshold_group ""
    set_db [get_db base_cells b15???????w* -if !.is_black_box] .voltage_threshold_group ELL
    set_db [get_db base_cells b15???????y* -if !.is_black_box] .voltage_threshold_group ELLLVT
  }
  if {$vars(INTEL_LIB_TYPE) == "6t108"} {
    set_db -quiet [get_db base_cells] .voltage_threshold_group ""
    set_db [get_db base_cells b0m???????h* -if !.is_black_box] .voltage_threshold_group LVT
    set_db [get_db base_cells b0m???????m* -if !.is_black_box] .voltage_threshold_group LPLVT
    set_db [get_db base_cells b0m???????n* -if !.is_black_box] .voltage_threshold_group NOM
    set_db [get_db base_cells b0m???????r* -if !.is_black_box] .voltage_threshold_group ULP
    set_db [get_db base_cells b0m???????s* -if !.is_black_box] .voltage_threshold_group ULVT
    set_db [get_db base_cells b0m???????l* -if !.is_black_box] .voltage_threshold_group LP
    set_db [get_db base_cells b0m???????q* -if !.is_black_box] .voltage_threshold_group HP
  }
  
  # Extraction attributes  [get_db -category extract_rc]
  #-----------------------------------------------------------------------------
  #NOTE:preroute settings are removed as there is no impact on SPEF correlation between postroute and post fill

  if {[is_flow -inside flow:route] || [is_flow -after flow:route ] } {
    puts "Applying Intel settings for route stage extraction."
    if { [is_flow -inside flow:opt_signoff] } {
        set_db extract_rc_effort_level signoff
        #Setting for Tempus timing accuracy
        set_db delaycal_socv_lvf_mode moments
        set_db delaycal_signoff_alignment_settings true
    } else {
        set_db extract_rc_effort_level high
    }
    set_db extract_rc_engine post_route 
    set_db extract_rc_coupled true 
    set_db extract_rc_lef_tech_file_map $vars(INTEL_QRC_LAYER_MAP)
  }

  # Floorplan attributes  [get_db -category floorplan]
  #-----------------------------------------------------------------------------

  #Setting macro placement grid to the modular grid
  puts "Restricting macros placement to be on modular grid ( $vars(INTEL_MD_GRID_X) , $vars(INTEL_MD_GRID_Y) )"
  set_preference ConstraintUserYGrid $vars(INTEL_MD_GRID_Y)
  set_preference ConstraintUserXGrid $vars(INTEL_MD_GRID_X)
  floorplan_set_snap_rule -for BLK -grid UG -force
  floorplan_set_snap_rule -for CORE -grid UG -force
  
  #to avoid m7 min port length violation
  set_pin_constraint -depth 0.54 -target_layers m7

  # Placement attributes  [get_db -category place]
  #-----------------------------------------------------------------------------
  
  # Optimization attributes  [get_db -category opt]
  #-----------------------------------------------------------------------------
  #Required for LVS
  set_db init_no_new_assigns true
  puts "init_no_new_assigns is: [get_db init_no_new_assigns]"
  
  # Clock attributes  [get_db -category cts]
  #-----------------------------------------------------------------------------
  
  # Routing attributes  [get_db -category route]
  #-----------------------------------------------------------------------------

  #To avoid via drops if overlap is not 100%
  set_db generate_special_via_partial_overlap_threshold 1

  ## ignore_followpin_vias for ignoring VIA1 drc during refine_place (on M1 Power Stripes in non-preferred direction)
  set_db design_ignore_followpin_vias true

  # Disable off grid routing, but still allow via drop to access macro pins off track
  set_db route_design_detail_on_grid_only {wire 1:1 via 1:1 pin_wire 1:1 pin_via 1:1}

  #To disable jog routing
  set_db route_design_detail_minimize_litho_effect_on_layer {t t t t t t t t}

  # align global route grid to macro blockages
  set_db route_design_use_blockage_for_auto_ggrid true

  # Strictly enforce any NDR rule.
  set_db route_design_strict_honor_route_rule true

  # specify the max distance for a non-default rule route taper
  set_db route_design_detail_taper_dist_limit 0

  # Disable post route wire spreading for SI avoidance.
  set_db route_design_detail_post_route_spread_wire false

  # disable advanced violation fixing
  set_db route_design_detail_exp_advanced_violation_fix C2CCol

  # use NDR for variable width wire.
  set_db route_design_exp_use_var_width_route_rule false

  # ensure via is inside pin shapes
  set_db route_design_with_via_in_pin "1:1"

  # Insert diode for clock net antenna violations
  set_db route_design_diode_insertion_for_clock_nets true

  #added to set dont_use attribute to true for clock cells during APR flow
  #it was set to false in syn_map stage for remapping
  #this step is same as 'set_dont_use' flow step
  if {[is_flow -inside flow:floorplan] } {
          foreach base_cell_name [list [get_flow_config dont_use_cells]] { 
              set_db [get_db base_cells $base_cell_name] .dont_use true
          }
  }

}


