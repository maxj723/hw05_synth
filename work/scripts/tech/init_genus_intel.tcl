##############################################################################
# STEP init_genus_intel
##############################################################################
create_flow_step -name init_genus_intel -skip_metric {

  #Source procedures used by tech modules
  foreach tclProc [glob  $env(TECH_MODULE_DIR)/procs/*tcl] {
    source -quiet $tclProc
  }

  # DKG technology configuration
  source -quiet $env(TECH_MODULE_DIR)/tech_config.tcl 
  source -quiet $env(TECH_MODULE_DIR)/default_settings.tcl

  # setup voltage threshold (VT) cell associations so VT reporting is accurate
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

  if { [get_feature synth_spatial] || [get_feature synth_ispatial] } {
    #properly handle backside metal
    set_db invs_preload_script $env(TECH_MODULE_DIR)/qrc_map.tcl
  }

  if {$vars(INTEL_LIB_TYPE) == "6t108"} {
    if {[is_flow -inside flow:syn_map]} {
      set_db [get_db lib_cells *b0mc*] .avoid false
      set_db [get_db lib_cells *b0mc*] .dont_use false
    }
    if {[is_flow -inside flow:syn_opt] && [is_flow -after flow:syn_opt.block_finish]} {
      set_db [get_db lib_cells *b0mc*] .avoid true
      set_db [get_db lib_cells *b0mc*] .dont_use true
    }
  } else {
    if {[is_flow -inside flow:syn_map]} {
      set_db [get_db lib_cells *b15c*] .avoid false
      set_db [get_db lib_cells *b15c*] .dont_use false
    }
    if {[is_flow -inside flow:syn_opt] && [is_flow -after flow:syn_opt.block_finish]} {
      set_db [get_db lib_cells *b15c*] .avoid true
      set_db [get_db lib_cells *b15c*] .dont_use true
    }
  }
  
  #to avoid LVS issues
  set_db  remove_assigns true
  puts "remove_assigns is: [get_db remove_assigns]"
}
