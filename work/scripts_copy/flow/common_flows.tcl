# Flowkit v21.12-s019_1

set_db flow_template_type {stylus}
set_db flow_template_version {1}
set_db flow_template_tools {innovus}
set_db flow_template_feature_definition {flow_express 0 report_inline {} report_defer {} report_none {} report_clp 0 report_lec 0 use_common_db 0 report_pba 0 opt_early_cts 1 clock_design 0 clock_flexible_htree {} opt_postcts_hold_disable 0 opt_postcts_split 0 route_filler_disable 0 route_track_opt {} route_secondary_nets 0 opt_postroute_split 0 opt_route 0 opt_signoff {} opt_em 0 opt_eco {} ff_setup 0}

#===============================================================================
# Common flow attributes
#===============================================================================

#- Specify qor html file to generate at the end of every flow
if {[is_attribute -obj_type root flowtool_metrics_qor_vivid]} {
  set_db flowtool_metrics_qor_vivid [file join [get_db flow_report_directory] qor.html]
  if {[file exists [file join [get_db init_flow_directory] metric_config.yaml]]} {
    read_metric_config -format vivid [file join [get_db init_flow_directory] metric_config.yaml]
  }
} else {
  set_db flowtool_metrics_qor_html [file join [get_db flow_report_directory] qor.um.html]
}

#- Define attribute for report name
if { ![is_attribute -obj_type root flow_report_name]} {
  define_attribute flow_report_name \
    -category flow \
    -data_type string \
    -default "" \
    -help_string "Name to use during report generation" \
    -obj_type root
}

#- Define attribute for report prefix
if { ![is_attribute -obj_type root flow_report_prefix]} {
  define_attribute flow_report_prefix \
    -category flow \
    -data_type string \
    -default "" \
    -help_string "File prefix to use during report generation" \
    -obj_type root
}

#- Specify Flow Header (runs at the start of run_flow command)
set_db flow_header_tcl {
  #- extend flow report name based on context
  if {[is_flow -quiet -inside flow:sta] || [is_flow -quiet -inside flow:sta_dmmmc] || [is_flow -quiet -inside flow:sta_eco]} {
    if {![regexp {sta$} [get_db flow_report_name]]} {
      set_db flow_report_name [expr {[string is space [get_db flow_report_name]] ? "sta" : "[get_db flow_report_name].sta"}]
    }
  } elseif {[is_flow -quiet -inside flow:ir_early_static] || [is_flow -quiet -inside flow:ir_early_dynamic]} {
    if {![regexp {era$} [get_db flow_report_name]]} {
      set_db flow_report_name [expr {[string is space [get_db flow_report_name]] ? "era" : "[get_db flow_report_name].era"}]
    }
  } elseif {[is_flow -quiet -inside flow:ir_grid] || [is_flow -quiet -inside flow:ir_static] || [is_flow -quiet -inside flow:ir_dynamic] || [is_flow -quiet -inside flow:ir_rampup]} {
    if {![regexp {ir$} [get_db flow_report_name]]} {
      set_db flow_report_name [expr {[string is space [get_db flow_report_name]] ? "ir" : "[get_db flow_report_name].ir"}]
    }
  } elseif {[is_flow -quiet -inside flow:sta_subflows] && [get_db flow_branch] ne {}} {
    set_db flow_report_name [get_db flow_branch]
  } elseif {[regexp {block_start|hier_start|eco_start} [get_db flow_step_current]]} {
    set_db flow_report_name [get_db [lindex [get_db flow_hier_path] end] .name]
  } else {
  }

  #- Create report dir (if necessary)
  file mkdir [file normalize [file join [get_db flow_report_directory] [get_db flow_report_name]]]
}



#=============================================================================
# Flow: Implementation Flows
#=============================================================================

create_flow -name init_innovus -owner cadence -tool innovus {init_innovus_yaml init_innovus_user}

create_flow -name init_design -owner cadence -tool innovus {read_mmmc read_physical read_netlist read_power_intent run_init_design}

set floorplan_steps {block_start init_design init_innovus set_dont_use init_floorplan commit_power_intent add_tracks block_finish}
if {![get_feature report_none] && ([get_feature report_inline] && ![get_feature report_defer])} { lappend floorplan_steps report_floorplan }
if {![get_feature report_none] && (![get_feature report_inline] && [get_feature report_defer])} { lappend floorplan_steps schedule_floorplan_report_floorplan }
if {![get_feature report_none] && (![get_feature report_inline] && ![get_feature report_defer])} { lappend floorplan_steps schedule_floorplan_report_floorplan }
create_flow -name floorplan -owner cadence -tool innovus -tool_options -disable_user_startup $floorplan_steps

set prects_steps {block_start init_innovus add_clock_spec}
if {[get_feature clock_flexible_htree]} { lappend prects_steps add_clock_htree_spec }
lappend prects_steps add_clock_route_types commit_route_types
if {[get_feature clock_flexible_htree]} { lappend prects_steps add_clock_htree }
lappend prects_steps run_place_opt block_finish
if {![get_feature report_none] && ([get_feature report_inline] && ![get_feature report_defer])} { lappend prects_steps report_prects }
if {![get_feature report_none] && (![get_feature report_inline] && [get_feature report_defer])} { lappend prects_steps schedule_prects_report_prects }
if {![get_feature report_none] && (![get_feature report_inline] && ![get_feature report_defer])} { lappend prects_steps schedule_prects_report_prects }
create_flow -name prects -owner cadence -tool innovus -tool_options -disable_user_startup $prects_steps

set cts_steps {block_start init_innovus add_clock_tree add_tieoffs block_finish}
if {![get_feature report_none] && ([get_feature report_inline] && ![get_feature report_defer])} { lappend cts_steps report_postcts }
if {![get_feature report_none] && (![get_feature report_inline] && [get_feature report_defer])} { lappend cts_steps schedule_cts_report_postcts }
if {![get_feature report_none] && (![get_feature report_inline] && ![get_feature report_defer])} { lappend cts_steps schedule_cts_report_postcts }
create_flow -name cts -owner cadence -tool innovus -tool_options -disable_user_startup $cts_steps

set postcts_steps {block_start init_innovus run_opt_postcts_hold block_finish}
if {![get_feature report_none] && ([get_feature report_inline] && ![get_feature report_defer])} { lappend postcts_steps report_postcts }
if {![get_feature report_none] && (![get_feature report_inline] && [get_feature report_defer])} { lappend postcts_steps schedule_postcts_report_postcts }
if {![get_feature report_none] && (![get_feature report_inline] && ![get_feature report_defer])} { lappend postcts_steps schedule_postcts_report_postcts }
create_flow -name postcts -owner cadence -tool innovus -tool_options -disable_user_startup $postcts_steps

set route_steps {block_start init_innovus add_fillers run_route block_finish}
if {![get_feature report_none] && ([get_feature report_inline] && ![get_feature report_defer])} { lappend route_steps report_postroute }
if {![get_feature report_none] && (![get_feature report_inline] && [get_feature report_defer])} { lappend route_steps schedule_route_report_postroute }
if {![get_feature report_none] && (![get_feature report_inline] && ![get_feature report_defer])} { lappend route_steps schedule_route_report_postroute }
create_flow -name route -owner cadence -tool innovus -tool_options -disable_user_startup $route_steps

set postroute_steps {block_start init_innovus run_opt_postroute block_finish}
if {![get_feature report_none] && ([get_feature report_inline] && ![get_feature report_defer])} { lappend postroute_steps report_postroute }
if {![get_feature report_none] && (![get_feature report_inline] && [get_feature report_defer])} { lappend postroute_steps schedule_postroute_report_postroute }
if {![get_feature report_none] && (![get_feature report_inline] && ![get_feature report_defer])} { lappend postroute_steps schedule_postroute_report_postroute }
create_flow -name postroute -owner cadence -tool innovus -tool_options -disable_user_startup $postroute_steps
if {[get_feature opt_signoff]} {
  
  set opt_signoff_steps {block_start init_innovus run_opt_signoff block_finish}
  if {![get_feature report_none] && ([get_feature report_inline] && ![get_feature report_defer])} { lappend opt_signoff_steps report_postroute }
  if {![get_feature report_none] && (![get_feature report_inline] && [get_feature report_defer])} { lappend opt_signoff_steps schedule_opt_signoff_report_postroute }
  if {![get_feature report_none] && (![get_feature report_inline] && ![get_feature report_defer])} { lappend opt_signoff_steps schedule_opt_signoff_report_postroute }
  create_flow -name opt_signoff -owner cadence -tool innovus -tool_options -disable_user_startup $opt_signoff_steps
}

set eco_steps {eco_start init_innovus init_eco run_place_eco run_route_eco}
if {[get_feature opt_eco]} { lappend eco_steps run_opt_eco }
lappend eco_steps eco_finish
if {![get_feature report_none] && ([get_feature report_inline] && ![get_feature report_defer])} { lappend eco_steps report_postroute }
if {![get_feature report_none] && (![get_feature report_inline] && [get_feature report_defer])} { lappend eco_steps schedule_eco_report_postroute }
if {![get_feature report_none] && (![get_feature report_inline] && ![get_feature report_defer])} { lappend eco_steps schedule_eco_report_postroute }
create_flow -name eco -owner cadence -tool innovus -tool_options -disable_user_startup $eco_steps

#=============================================================================
# Flow: Reporting Flows
#=============================================================================

if {![get_feature report_none]} {
  if {![get_feature report_none]} { create_flow -name report_floorplan -owner cadence -tool innovus -tool_options -disable_user_startup {report_start init_innovus report_check_design report_area_innovus report_route_drc report_finish} }
  
  if {![get_feature report_none]} { create_flow -name report_prects -owner cadence -tool innovus -tool_options -disable_user_startup {report_start init_innovus report_check_design report_area_innovus report_late_summary_innovus report_late_paths report_power_innovus report_finish} }
  
  if {![get_feature report_none]} { create_flow -name report_postcts -owner cadence -tool innovus -tool_options -disable_user_startup {report_start init_innovus report_check_design report_area_innovus report_early_summary_innovus report_early_paths report_late_summary_innovus report_late_paths report_clock_timing report_power_innovus report_finish} }
  
  if {![get_feature report_none]} { create_flow -name report_postroute -owner cadence -tool innovus -tool_options -disable_user_startup {report_start init_innovus report_check_design report_area_innovus report_early_summary_innovus report_early_paths report_late_summary_innovus report_late_paths report_clock_timing report_power_innovus report_route_drc report_route_density report_finish} }
}
#=============================================================================
# Flow: Toplevel Flows
#=============================================================================
set implementation_steps {floorplan prects cts postcts route postroute}
if {[get_feature opt_signoff]} { lappend implementation_steps opt_signoff }

create_flow -name implementation -tool innovus -owner cadence -skip_metric -tool_options -disable_user_startup $implementation_steps

create_flow -name block -owner cadence -skip_metric {implementation}
set_db flow_top flow:block
