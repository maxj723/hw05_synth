create_flow_step -name pre_db -owner intel { 
  if {[get_db program_short_name]=="innovus" || [get_db program_short_name]=="tempus" } { 
    source $env(TECH_MODULE_DIR)/qrc_map.tcl

    # Enable connections to mustjoin pins
    # This setting must be done before loading the phyical LEF files or a DB.
    set_db read_physical_must_join_all_ports true
    set_db timing_derate_spatial_distance_unit 1um


    set_db timing_library_setup_sigma_multiplier 1.5
    set_db timing_library_hold_sigma_multiplier 3

  }
}
# This setting must be done before loading the phyical LEF files or a DB. It technically
#  only needs to be once. However, we must put it in before "read_db" in the case when Stylus flow
#  instructs Innovus to load the Genus syn_opt DB. If a flow was Innovus only, it could go into the flow
#  as a single command before init_design, after block_start. The approach taken here is redundant, but works
#  regardless of flow configuration. 
edit_flow -after Cadence.plugin.flowkit.read_db.pre -append pre_db

