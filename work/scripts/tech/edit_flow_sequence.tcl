
edit_flow -after synthesis.syn_opt.run_syn_opt -append remap_data_cells -unique
edit_flow -after init_genus.init_genus_yaml -append init_genus_intel -unique

edit_flow -after implementation.floorplan.commit_power_intent -append ndr_definition -unique
edit_flow -after ndr_definition -append create_row -unique
edit_flow -after add_tracks -append macro_placement -unique
edit_flow -after macro_placement -append create_macro_ws -unique
edit_flow -after create_macro_ws -append create_rectilinear_routing_blockage -unique
edit_flow -after create_rectilinear_routing_blockage  -append global_net_connect -unique
edit_flow -after global_net_connect   -append create_pg_grid_procs -unique
edit_flow -after create_pg_grid_procs   -append create_pg_grid -unique
edit_flow -after create_pg_grid   -append create_boundary_ws -unique
edit_flow -after create_boundary_ws   -append  create_boundary_si_blockage -unique
edit_flow -after create_boundary_si_blockage   -append  pre_place_bonus_fib -unique
edit_flow -after pre_place_bonus_fib   -append  add_tap_cells -unique
edit_flow -after add_tap_cells   -append  pre_place_fiducial -unique
edit_flow -after pre_place_fiducial   -append  insert_antenna_diodes_on_input -unique
edit_flow -after insert_antenna_diodes_on_input   -append  create_check_grid -unique
#edit_flow -after create_check_grid   -append  check_floorplan -unique
#edit_flow -after check_floorplan   -append  create_top_pg_pin -unique
edit_flow -after create_check_grid -append  create_top_pg_pin -unique
edit_flow -after create_top_pg_pin -append  check_floorplan -unique

edit_flow -after run_opt_postroute -append extend_tgoxid -unique
edit_flow -after extend_tgoxid -append remove_boundary_blockage -unique
edit_flow -after implementation.postroute.block_finish -append write_oas -unique

edit_flow -after implementation.opt_signoff.init_innovus -append read_parasitics -unique
edit_flow -after implementation.opt_signoff.block_finish -append write_oas -unique

edit_flow -after init_innovus.init_innovus_yaml -append init_innovus_intel -unique
edit_flow -after init_tempus.init_tempus_yaml -append init_tempus_intel -unique
