##############################################################################
# STEP init_tempus_intel
##############################################################################
create_flow_step -name init_tempus_intel -skip_metric {

  #Source procedures used by tech modules
  foreach tclProc [glob  $env(TECH_MODULE_DIR)/procs/*tcl] {
    source -quiet $tclProc
  }

  # DKG technology configuration
  source -quiet $env(TECH_MODULE_DIR)/tech_config.tcl 
  source -quiet $env(TECH_MODULE_DIR)/default_settings.tcl


  set_db timing_report_enable_verbose_ssta_mode true
  set_db timing_report_fields { instance arc cell delay delay_mean delay_sigma user_derate socv_derate total_derate arrival arrival_mean arrival_sigma  required }
  set_db timing_enable_spatial_derate_mode true
  set_db timing_spatial_derate_distance_mode chip_size

}
