# Flowkit v21.12-s019_1
################################################################################
# This file contains content which is used to customize the refererence flow
# process.  Commands such as 'create_flow', 'create_flow_step' and 'edit_flow'
# would be most prevalent.  For example:
#
# create_flow_step -name write_sdf -owner user -write_db {
#   write_sdf [get_db flow_report_directory]/[get_db flow_report_name].sdf
# }
#
# edit_flow -after flow_step:innovus_report_late_timing -append flow_step:write_sdf
#
################################################################################

################################################################################
# FLOW METRIC HEADER SETTINGS
################################################################################
set_metric_header -name run_name -value [get_db flow_run_tag]
set_metric_header -name run_remark -value [get_db flow_remark]

################################################################################
# FLOW CPU AND HOST SETTINGS
################################################################################
create_flow_step -name init_mcpu -owner flow {
  apply {{} {
    # Multi host/cpu attributes
    #-----------------------------------------------------------------------------
    # The FLOWTOOL_NUM_CPUS is an environment variable which should be exported by
    # the specified dist script.  This connects the number of CPUs being reserved
    # for batch jobs with the current flow scripts.  The LSB_MAX_NUM_PROCESSORS is
    # a typical environment variable exported by distribution platforms and is
    # useful for ensuring all interactive jobs are using the reserved amount of CPUs.
    if {[info exists ::env(FLOWTOOL_NUM_CPUS)]} {
      set max_cpus $::env(FLOWTOOL_NUM_CPUS)
    } elseif {[info exists ::env(LSB_MAX_NUM_PROCESSORS)]} {
      set max_cpus $::env(LSB_MAX_NUM_PROCESSORS)
    } else {
      set max_cpus 1
    }
    switch -glob [get_db program_short_name] {
      default       {}
      joules*       -
      genus*        -
      innovus*      -
      tempus*       -
      voltus*       { set_multi_cpu_usage -verbose -local_cpu $max_cpus }
    }
if {[get_feature opt_signoff]} {
      if {[is_flow -inside flow:opt_signoff]} {
        set_multi_cpu_usage -verbose -remote_host         < PLACEHOLDER: NUMBER OF REMOTE HOSTS >
        set_multi_cpu_usage -verbose -cpu_per_remote_host < PLACEHOLDER: NUMBER OF CPUS PER REMOTE HOSTS >
        set_distributed_hosts                             < PLACEHOLDER: DISTRIBUTED HOST OPTIONS >
      }
}
  }}
}
edit_flow -after Cadence.plugin.flowkit.read_db.pre -append flow_step:init_mcpu
edit_flow -after Cadence.plugin.flowkit.read_db.post -append flow_step:init_mcpu

################################################################################
# FLOW CUSTOMIZATIONS / FLOW STEP ADDITIONS
################################################################################
if {![get_feature report_none]} {
  
  ############################################################################
  # STEP report_late_paths
  ############################################################################
  create_flow_step -name report_late_paths -owner flow -exclude_time_metric {
    #- Reports that show detailed timing with Graph Based Analysis (GBA)
    report_timing -max_paths 5   -nworst 1 -path_type endpoint        > [file join [get_db flow_report_directory] [get_db flow_report_name] setup.endpoint.rpt]
    report_timing -max_paths 1   -nworst 1 -path_type full_clock -net > [file join [get_db flow_report_directory] [get_db flow_report_name] setup.worst.rpt]
    report_timing -max_paths 500 -nworst 1 -path_type full_clock      > [file join [get_db flow_report_directory] [get_db flow_report_name] setup.gba.rpt]
  }
  
  ############################################################################
  # STEP report_early_paths
  ############################################################################
  create_flow_step -name report_early_paths -owner flow -exclude_time_metric {
    #- Reports that show detailed early timing with Graph Based Analysis (GBA)
    report_timing -early -max_paths 5   -nworst 1 -path_type endpoint        > [file join [get_db flow_report_directory] [get_db flow_report_name] hold.endpoint.rpt]
    report_timing -early -max_paths 1   -nworst 1 -path_type full_clock -net > [file join [get_db flow_report_directory] [get_db flow_report_name] hold.worst.rpt]
    report_timing -early -max_paths 500 -nworst 1 -path_type full_clock      > [file join [get_db flow_report_directory] [get_db flow_report_name] hold.gba.rpt]
  }
}
