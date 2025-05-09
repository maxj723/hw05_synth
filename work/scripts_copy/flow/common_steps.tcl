# Flowkit v21.12-s019_1
#- common_steps.tcl : defines flow_steps used in mutiple flows

define_feature setup_views -type string -description "list of setup analysis_views to activate"
define_feature hold_views -type string -description "list of hold analysis_views to activate"
define_feature dynamic_view -type string -description "single dynamic analysis_view to activate"
define_feature leakage_view -type string -description "single leakage analysis_view to activate"
#===============================================================================
# Common flow_steps for init_design
#===============================================================================

##############################################################################
# STEP read_mmmc
##############################################################################
create_flow_step -name read_mmmc -owner cadence {
  apply {{} {
    set FH [open [file join [get_db flow_db_directory] [get_db flow_report_name].mmmc_config.tcl] w]
  
    puts $FH "##############################################################################"
    puts $FH "## LIBRARY SETS"
    puts $FH "##############################################################################"
    foreach name [dict keys [get_flow_config library_sets]] {
  
      set library_files [get_flow_config -quiet library_sets $name library_files]
      set link_files    [get_flow_config -quiet library_sets $name link_library_files]
      set target_files  [get_flow_config -quiet library_sets $name target_library_files]
      set aocv_files    [get_flow_config -quiet library_sets $name aocv_files]
      set lvf_files     [get_flow_config -quiet library_sets $name lvf_files]
      set si_files      [get_flow_config -quiet library_sets $name si_files]
      set socv_files    [get_flow_config -quiet library_sets $name socv_files]
  
      puts $FH "create_library_set \\"
      puts $FH "  -name $name \\"
      #- define timing_files (.ldb/.lib)
      if {[llength $library_files] > 0} {
        puts $FH "  -timing \\"
        puts $FH "    \[list \\"
        if {[llength $library_files] != [llength [join $library_files]]} {
          foreach inner_list $library_files {
            puts $FH "      \[list \\"
            foreach file $inner_list {
              puts $FH "        [file normalize $file] \\"
            }
            puts $FH "      \] \\"
          }
        } else {
          foreach file $library_files {
            puts $FH "      [file normalize $file] \\"
          }
        }
        if {[llength [concat $aocv_files $lvf_files $si_files $socv_files]] > 0 } {
          puts $FH "    \] \\"
        } else {
          puts $FH "    \]"
        }
      }
      #- define link/target timing_files (.ldb/.lib)
      if {[llength $link_files] > 0 && [llength $target_files] > 0} {
        puts $FH "  -link_timing \\"
        puts $FH "    \[list \\"
        foreach file $link_files {
          puts $FH "      [file normalize $file] \\"
        }
        puts $FH "    \] \\"
        puts $FH "  -target_timing \\"
        puts $FH "    \[list \\"
        foreach file $target_files {
          puts $FH "      [file normalize $file] \\"
        }
        if {[llength [concat $aocv_files $lvf_files $si_files $socv_files]] > 0 } {
          puts $FH "    \] \\"
        } else {
          puts $FH "    \]"
        }
      }
      #- define aocv files
      if {[llength $aocv_files] > 0 } {
        puts $FH "  -aocv \\"
        puts $FH "    \[list \\"
        foreach file $aocv_files {
          puts $FH "      [file normalize $file] \\"
        }
        if {[llength [concat $lvf_files $si_files $socv_files]] > 0 } {
          puts $FH "    \] \\"
        } else {
          puts $FH "    \]"
        }
      }
      #- define lvf files
      if {[llength $lvf_files] > 0 } {
        puts $FH "  -lvf \\"
        puts $FH "    \[list \\"
        foreach file $lvf_files {
          puts $FH "      [file normalize $file] \\"
        }
        if {[llength [concat $si_files $socv_files]] > 0 } {
          puts $FH "    \] \\"
        } else {
          puts $FH "    \]"
        }
      }
      #- define si files (.cdb)
      if {[llength $si_files] > 0 } {
        puts $FH "  -si     \\"
        puts $FH "    \[list \\"
        foreach file $si_files {
          puts $FH "      [file normalize $file] \\"
        }
        if {[llength [concat $socv_files]] > 0 } {
          puts $FH "    \] \\"
        } else {
          puts $FH "    \]"
        }
      }
      #- define socv files
      if {[llength $socv_files] > 0 } {
        puts $FH "  -socv   \\"
        puts $FH "    \[list \\"
        foreach file $socv_files {
          puts $FH "      [file normalize $file] \\"
        }
        puts $FH "    \]"
      }
      puts $FH ""
    }
    puts $FH ""
    puts $FH "##############################################################################"
    puts $FH "## OPERATING CONDITIONS"
    puts $FH "##############################################################################"
    foreach name [dict keys [get_flow_config -quiet opconds]] {
      set op_cond_process      [get_flow_config -quiet opconds $name process]
      set op_cond_voltage      [get_flow_config -quiet opconds $name voltage]
      set op_cond_temperature  [get_flow_config -quiet opconds $name temperature]
  
      puts $FH "create_opcond \\"
      puts $FH "  -name $name \\"
      if ![string is space $op_cond_process] {
        puts $FH "  -process $op_cond_process \\"
      }
      if ![string is space $op_cond_voltage] {
        puts $FH "  -voltage $op_cond_voltage \\"
      }
      if ![string is space $op_cond_temperature] {
        puts $FH "  -temperature $op_cond_temperature \\"
      }
      puts $FH ""
    }
    puts $FH ""
    puts $FH "###############################################################################"
    puts $FH "### RC CORNERS"
    puts $FH "###############################################################################"
    foreach name [dict keys [get_flow_config rc_corners]] {
      set rc_corner_qrc_tech    [get_flow_config -quiet rc_corners $name qrc_tech_file]
      set rc_corner_temperature [get_flow_config -quiet rc_corners $name temperature]
  
      puts $FH "create_rc_corner \\"
      puts $FH "  -name $name \\"
      if ![string is space $rc_corner_temperature] {
        puts $FH "  -temperature $rc_corner_temperature \\"
      }
      if ![string is space $rc_corner_qrc_tech] {
        puts $FH "  -qrc_tech $rc_corner_qrc_tech"
      }
      puts $FH ""
    }
    puts $FH ""
    puts $FH "##############################################################################"
    puts $FH "## TIMING CONDITIONS"
    puts $FH "##############################################################################"
    foreach name [dict keys [get_flow_config timing_conditions]] {
      set timing_condition_lib_set [get_flow_config -quiet timing_conditions $name library_sets]
      set timing_condition_opcond  [get_flow_config -quiet timing_conditions $name opcond]
      set timing_condition_opcond_lib  [get_flow_config -quiet timing_conditions $name opcond_library]
  
      puts $FH "create_timing_condition \\"
      puts $FH "  -name $name \\"
  
      #- Timing Condition library sets validation
      puts $FH "  -library_sets \\"
      puts $FH "    \[list \\"
      foreach tc_lib_set $timing_condition_lib_set {
        puts $FH "        $tc_lib_set \\"
      }
      if {[llength [concat $timing_condition_opcond $timing_condition_opcond_lib]] > 0 } {
        puts $FH "    \] \\"
      } else {
        puts $FH "    \]"
      }
      if {![string is space $timing_condition_opcond]} {
        if {![string is space $timing_condition_opcond_lib]} {
          puts $FH "  -opcond $timing_condition_opcond \\"
          puts $FH "  -opcond_library $timing_condition_opcond_lib"
        } else {
         puts $FH "  -opcond $timing_condition_opcond"
       }
      }
      puts $FH ""
    }
    puts $FH ""
    puts $FH "###############################################################################"
    puts $FH "### DELAY CORNERS"
    puts $FH "###############################################################################"
    foreach name [dict keys [get_flow_config delay_corners]] {
      set delay_corner_early_rc_corner  [get_flow_config -quiet delay_corners $name rc_corner early]
      set delay_corner_late_rc_corner   [get_flow_config -quiet delay_corners $name rc_corner late]
      set delay_corner_early_timing_condition [get_flow_config -quiet delay_corners $name timing_condition early]
      set delay_corner_late_timing_condition  [get_flow_config -quiet delay_corners $name timing_condition late]
  
      puts $FH "create_delay_corner \\"
      puts $FH "  -name $name \\"
  
      #- define delay_corner -rc_corner
      if {![string is space $delay_corner_early_rc_corner] && ![string is space $delay_corner_late_rc_corner]} {
        if {$delay_corner_early_rc_corner eq $delay_corner_late_rc_corner} {
          puts $FH "  -rc_corner $delay_corner_early_rc_corner \\"
        } else {
          puts $FH "  -early_rc_corner $delay_corner_early_rc_corner \\"
          puts $FH "  -late_rc_corner $delay_corner_late_rc_corner \\"
        }
      }
      #- define delay_corner -timing_condition
      if {![string is space $delay_corner_early_timing_condition] && ![string is space $delay_corner_late_timing_condition]} {
        if {$delay_corner_early_timing_condition eq $delay_corner_late_timing_condition} {
          puts $FH "  -timing_condition [list $delay_corner_early_timing_condition]"
        } else {
          puts $FH "  -early_timing_condition [list $delay_corner_early_timing_condition] \\"
          puts $FH "  -late_timing_condition [list $delay_corner_late_timing_condition]"
        }
      }
      puts $FH ""
    }
    puts $FH ""
    puts $FH "###############################################################################"
    puts $FH "### CONSTRAINT MODES"
    puts $FH "###############################################################################"
    foreach name [dict keys [get_flow_config constraint_modes]] {
      set constraint_mode_sdc       [get_flow_config -quiet constraint_modes $name sdc_files]
      set constraint_mode_tcl_vars  [get_flow_config -quiet constraint_modes $name tcl_variables]
  
      puts $FH "create_constraint_mode \\"
      puts $FH "  -name $name \\"
      #- Constraint_mode -sdc_files
      puts $FH "  -sdc_files \\"
      puts $FH "    \[list \\"
      foreach file $constraint_mode_sdc {
        puts $FH "      [file normalize $file] \\"
      }
      #- Constraint_mode -tcl_vars
      if ![string is space $constraint_mode_tcl_vars] {
        puts $FH "    \] \\"
        puts $FH "  -tcl_variables \{$constraint_mode_tcl_vars\}"
      } else {
        puts $FH "    \]"
      }
      puts $FH ""
    }
    puts $FH ""
    puts $FH "###############################################################################"
    puts $FH "### ANALYSIS VIEWS"
    puts $FH "###############################################################################"
    set analysis_view_is_setup_list   ""
    set analysis_view_is_hold_list    ""
    set analysis_view_is_dynamic_list ""
    set analysis_view_is_leakage_list ""
    foreach name [dict keys [get_flow_config analysis_views]] {
      puts $FH "create_analysis_view \\"
      puts $FH "  -name $name \\"
      puts $FH "  -constraint_mode [get_flow_config -quiet analysis_views $name constraint_mode] \\"
      if {![string is space [get_flow_config -quiet analysis_views $name power_modes]]} {
        puts $FH "  -power_modes [get_flow_config -quiet analysis_views $name power_modes] \\"
      }
      puts $FH "  -delay_corner [get_flow_config -quiet analysis_views $name delay_corner]"
      #- Sort views by purpose
      if {[string is true -strict [get_flow_config -quiet analysis_views $name is_setup]]} {
        lappend analysis_view_is_setup_list $name
      }
      if {[string is true -strict [get_flow_config -quiet analysis_views $name is_hold]]} {
        lappend analysis_view_is_hold_list $name
      }
      if {[string is true -strict [get_flow_config -quiet analysis_views $name is_leakage]]} {
        lappend analysis_view_is_leakage_list $name
      }
      if {[string is true -strict [get_flow_config -quiet analysis_views $name is_dynamic]]} {
        lappend analysis_view_is_dynamic_list $name
      }
      puts $FH ""
    }
  
    #- Override view list with feature values when available
    if {[get_feature setup_views] ne ""} {
      set analysis_view_is_setup_list [get_feature setup_views]
    }
    if {[get_feature hold_views] ne ""} {
      set analysis_view_is_hold_list [get_feature hold_views]
    }
    if {[get_feature leakage_view] ne ""} {
      set analysis_view_is_leakage_list [get_feature leakage_view]
    }
    if {[get_feature dynamic_view] ne ""} {
      set analysis_view_is_dynamic_list [get_feature dynamic_view]
    }
  
    #- Configure the Analysis View
    puts $FH "set_analysis_view \\"
    puts $FH "  -setup   \[list $analysis_view_is_setup_list\] \\"
    if {[llength $analysis_view_is_leakage_list] > 0 && [llength $analysis_view_is_dynamic_list] > 0} {
      puts $FH "  -hold    \[list $analysis_view_is_hold_list\] \\"
      puts $FH "  -leakage \[list $analysis_view_is_leakage_list\] \\"
      puts $FH "  -dynamic \[list $analysis_view_is_dynamic_list\]"
    } elseif {[llength $analysis_view_is_leakage_list] > 0 && [llength $analysis_view_is_dynamic_list] == 0} {
      puts $FH "  -hold    \[list $analysis_view_is_hold_list\] \\"
      puts $FH "  -leakage \[list $analysis_view_is_leakage_list\]"
    } elseif {[llength $analysis_view_is_leakage_list] == 0 && [llength $analysis_view_is_dynamic_list] > 0} {
      puts $FH "  -hold    \[list $analysis_view_is_hold_list\] \\"
      puts $FH "  -dynamic \[list $analysis_view_is_dynamic_list\]"
    } else {
      puts $FH "  -hold    \[list $analysis_view_is_hold_list\]"
    }
    puts $FH ""
    close $FH
  
    #- Read MMMC file
    if {[is_flow -inside flow:init_design]} {
      read_mmmc [file join [get_db flow_db_directory] [get_db flow_report_name].mmmc_config.tcl]
    }
  }}
} -check {
  apply {{} {
    #- Check: library_sets are defined
    check "[llength [get_flow_config -quiet library_sets]]" "A library_set object is required for MMMC.  None were found in the MMMC section of setup.yaml."
    foreach name [dict keys [get_flow_config -quiet library_sets]] {
      #- Check: library_sets do not have both timing and link/target libraries defined
      check "([llength [get_flow_config -quiet library_sets $name library_files]] || [llength [get_flow_config -quiet library_sets $name link_library_files]] || [llength [get_flow_config -quiet library_sets $name target_library_files]])" "Timing files are required for library_set: $name.  Must specify either library_files or link_library_files and target_library_files."
      check "!([llength [get_flow_config -quiet library_sets $name library_files]] && [llength [get_flow_config -quiet library_sets $name link_library_files]])" "The library specification for library_set: $name is incorrect.  Can not use library_files and link_library_files at the same time."
      check "!([llength [get_flow_config -quiet library_sets $name library_files]] && [llength [get_flow_config -quiet library_sets $name target_library_files]])" "The library specification for library_set: $name is incorrect.  Can not use library_files and target_library_files at the same time."
      check "!(([llength [get_flow_config -quiet library_sets $name link_library_files]] ? 1 : 0) ^ ([llength [get_flow_config -quiet library_sets $name target_library_files]] ? 1 : 0))" "The library specification for library_set: $name is incorrect.  Must specify both link_library_files and target_library_files."
      #- Check: library_sets reference valid files
      foreach file [join [get_flow_config -quiet library_sets $name library_files]] {
        check "[file exists $file] && [file readable $file]" "The library file: $file was not found or is not readable for library_set: $name"
      }
      foreach file [join [get_flow_config -quiet library_sets $name link_library_files]] {
        check "[file exists $file] && [file readable $file]" "The link library file: $file was not found or is not readable for library_set: $name"
      }
      foreach file [join [get_flow_config -quiet library_sets $name target_library_files]] {
        check "[file exists $file] && [file readable $file]" "The target library file: $file was not found or is not readable for library_set: $name"
      }
      foreach file [get_flow_config -quiet library_sets $name aocv_files] {
        check "[file exists $file] && [file readable $file]" "The aocv: $file was not found or is not readable for library_set: $name"
      }
      foreach file [get_flow_config -quiet library_sets $name lvf_files] {
        check "[file exists $file] && [file readable $file]" "The lvf file: $file was not found or is not readable for library_set: $name"
      }
      foreach file [get_flow_config -quiet library_sets $name si_files] {
        check "[file exists $file] && [file readable $file]" "The si file: $file was not found or is not readable for library_set: $name"
      }
      foreach file [get_flow_config -quiet library_sets $name socv_files] {
        check "[file exists $file] && [file readable $file]" "The socv file: $file was not found or is not readable for library_set: $name"
      }
    }
    #- Check: rc_corners are defined
    check "[llength [get_flow_config -quiet rc_corners]]" "A rc_corner object is required for MMMC.  None were found in the MMMC section of setup.yaml."
    foreach name [dict keys [get_flow_config -quiet rc_corners]] {
      foreach file [get_flow_config -quiet rc_corners $name qrc_tech_file] {
        check "[file exists $file] && [file readable $file]" "The qrc_tech file: $file was not found or is not readable for rc_corner: $name"
      }
    }
    #- Check: timing_conditions are defined
    check "[llength [get_flow_config -quiet timing_conditions]]" "A timing_condition object is required for MMMC.  None were found in the MMMC section of setup.yaml."
    foreach name [dict keys [get_flow_config -quiet timing_conditions]] {
      check "[llength [get_flow_config -quiet timing_conditions $name library_sets]]" "No library_sets found for timing_condition: $name"
      foreach tc_lib_set [get_flow_config -quiet timing_conditions $name library_sets] {
        check "[dict exists [get_flow_config -quiet library_sets] $tc_lib_set]" "The timing_condition: $name, referenced a library_set: $tc_lib_set which is not found in the library_set section of the setup.yaml\n  Possible library_sets are: [dict keys [get_flow_config -quiet library_sets]]"
      }
    }
    #- Check: delay_corners are defined
    check "[llength [get_flow_config -quiet delay_corners]]" "A delay_corner objects is required for MMMC.  None were found in the MMMC section of setup.yaml."
    foreach name [dict keys [get_flow_config delay_corners]] {
      #- Check: delay_corner has early and late rc_corners specified
      check "[llength [get_flow_config -quiet delay_corners $name rc_corner early]] && [llength [get_flow_config -quiet delay_corners $name rc_corner late]]" "The rc_corner specification for delay_corner: $name is incorrect.  Need both early and late rc_corner specified in MMMC section of setup.yaml."
      check "[dict exists [get_flow_config -quiet rc_corners] [get_flow_config delay_corners $name rc_corner early]]" "An early rc_corner was not found for delay_corner: $name\n  Possible rc_corners are: [dict keys [get_flow_config -quiet rc_corners]]"
      check "[dict exists [get_flow_config -quiet rc_corners] [get_flow_config delay_corners $name rc_corner late]]" "A late rc_corner was not found for delay_corner: $name\n  Possible rc_corners are: [dict keys [get_flow_config -quiet rc_corners]]"
      #- Check: delay_corner has early and late timing_conditions specified
      check "[llength [get_flow_config -quiet delay_corners $name timing_condition early]] && [llength [get_flow_config -quiet delay_corners $name timing_condition late]]" "The timing_condition specification for delay_corner: $name is incorrect.  Need both early and late timing_condition specified in MMMC section of setup.yaml."
      foreach tc [get_flow_config -quiet delay_corners $name timing_condition early] {
        if {[regexp {@(\S+)$} $tc match tc_name]} {} else {set tc_name $tc}
        check "[dict exists [get_flow_config -quiet timing_conditions] $tc_name]" "The specified early timing_condition $tc_name was not found for delay_corner $name\n  Possible timing_conditions are: [dict keys [get_flow_config -quiet timing_conditions]]"
      }
      foreach tc [get_flow_config -quiet delay_corners $name timing_condition late] {
        if {[regexp {@(\S+)$} $tc match tc_name]} {} else {set tc_name $tc}
        check "[dict exists [get_flow_config -quiet timing_conditions] $tc_name]" "The specified late timing_condition $tc_name was not found for delay_corner $name\n  Possible timing_conditions are: [dict keys [get_flow_config -quiet timing_conditions]]"
      }
    }
    #- Check: constraint_modes are defined
    check "[llength [get_flow_config -quiet constraint_modes]]" "A constraint_mode object is required for MMMC.  None were found in the MMMC section of setup.yaml."
    foreach name [dict keys [get_flow_config -quiet constraint_modes]] {
      #- Check: Constraint_mode has an SDC file
      check "[llength [get_flow_config -quiet constraint_modes $name sdc_files]]" "A list of sdc_files are required for constraint_mode: $name"
      foreach file [get_flow_config -quiet constraint_modes $name sdc_files] {
        check "[file exists $file] && [file readable $file]" "The sdc file: $file was not found or is not readable for constraint_mode: $name"
      }
    }
    #- Check: analysis_views are defined
    check "[llength [get_flow_config -quiet analysis_views]]" "An analysis_view objects is required for MMMC.  None were found in the MMMC section of setup.yaml."
    foreach name [dict keys [get_flow_config -quiet analysis_views]] {
      #- Check: Analysis_view has a constraint_mode
      check "[dict exists [get_flow_config -quiet constraint_modes] [get_flow_config analysis_views $name constraint_mode]]" "A constraint_mode was not found for analysis_view: $name\n  Possible constraint_modes are: [dict keys [get_flow_config -quiet constraint_modes]]"
      #- Check: Analysis_view has a delay_corner
      check "[dict exists [get_flow_config -quiet delay_corners] [get_flow_config analysis_views $name delay_corner]]" "A delay_corner was not found for analysis_view: $name\n  Possible delay_corners are: [dict keys [get_flow_config -quiet delay_corners]]"
      #- Sort views by purpose
      if {[string is true -strict [get_flow_config -quiet analysis_views $name is_setup]]} {
        lappend analysis_view_is_setup_list $name
      }
      if {[string is true -strict [get_flow_config -quiet analysis_views $name is_hold]]} {
        lappend analysis_view_is_hold_list $name
      }
      if {[string is true -strict [get_flow_config -quiet analysis_views $name is_leakage]]} {
        lappend analysis_view_is_leakage_list $name
      }
      if {[string is true -strict [get_flow_config -quiet analysis_views $name is_dynamic]]} {
        lappend analysis_view_is_dynamic_list $name
      }
    }
    if {[get_feature setup_views] ne ""} {
      set analysis_view_is_setup_list [list [get_feature setup_views]]
    }
    if {[get_feature hold_views] ne ""} {
      set analysis_view_is_hold_list [list [get_feature hold_views]]
    }
    if {[get_feature leakage_view] ne ""} {
      set analysis_view_is_leakage_list [list [get_feature leakage_view]]
    }
    if {[get_feature dynamic_view] ne ""} {
      set analysis_view_is_dynamic_list [list [get_feature dynamic_view]]
    }
  
    #- Check: Analysis_view has an active setup view
    check "[info exists analysis_view_is_setup_list]" "At least 1 view is required for setup analysis"
  
    #- Check: Analysis_view has an active hold view
    check "[info exists analysis_view_is_hold_list]" "At least 1 view is required for hold analysis"
  
    #- Check: Analysis_view has no more than one leakage view
    if {[info exists analysis_view_is_leakage_list]} {
      check "[llength $analysis_view_is_leakage_list] == 1" "Only one leakage view can be specified. Please select only one of the views specified: $analysis_view_is_leakage_list"
    }
    #- Check: Analysis_view has no more than one dynamic view
    if {[info exists analysis_view_is_dynamic_list]} {
      check "[llength $analysis_view_is_dynamic_list] == 1" "Only one dynamic view can be specified. Please select only one of the views specified: $analysis_view_is_dynamic_list"
    }
    #- Check: Analysis_view has both leakage andy dynamic views when specified
    if {[info exists analysis_view_is_leakage_list] || [info exists analysis_view_is_dynamic_list]} {
      check "[info exists analysis_view_is_leakage_list] && [info exists analysis_view_is_dynamic_list]" "Must specify both a leakage and a dynamic view when either is selected."
    }
  }}
}

##############################################################################
# STEP read_physical
##############################################################################
create_flow_step -name read_physical -owner cadence {
  apply {{} {
    if {![string is space [get_flow_config -quiet init_physical_files lef_files]]} {
      read_physical -lef [get_flow_config init_physical_files lef_files]
    }
    if {![string is space [get_flow_config -quiet init_physical_files oa_ref_libs]]} {
      set flow_startup_directory [get_db flow_startup_directory]
      set flow_top_directory [file normalize [get_db flow_working_directory]]
      if {![string is space [get_flow_config -quiet init_physical_files oa_search_libs]]} {
        set cmd "[list read_physical -oa_ref_libs [get_flow_config init_physical_files oa_ref_libs] -oa_search_libs [get_flow_config init_physical_files oa_search_libs]]"
      } else {
        set cmd "[list read_physical -oa_ref_libs [get_flow_config init_physical_files oa_ref_libs]]"
      }
  
      if {$flow_startup_directory ne $flow_top_directory} {
        cd $flow_startup_directory
        eval $cmd
        cd $flow_top_directory
      } else {
        eval $cmd
      }
    }
  }}
} -check {
  apply {{} {
    if {[llength [get_flow_config -quiet init_physical_files lef_files]] && [llength [get_flow_config -quiet init_physical_files oa_ref_libs]]} {
      check "0" "The read_physical specification is incorrect in setup.yaml. Please specify either lef_files or oa_ref_libs but not both."
    } elseif {![string is space [get_flow_config -quiet init_physical_files oa_search_libs]]} {
      check "[llength [get_flow_config -quiet init_physical_files oa_ref_libs]]" "Can not specify oa_search_libs without specifying oa_ref_libs for read_physical section in setup.yaml"
      check "[llength [get_flow_config -quiet init_physical_files lef_files]] == 0" "Can not specify oa_search_libs with lef_files for read_physical section in setup.yaml.  Only use oa_search_libs when specifying oa_ref_libs."
    } elseif {[llength [get_flow_config -quiet init_physical_files lef_files]] || [llength [get_flow_config -quiet init_physical_files oa_ref_libs]]} {
      check "!([llength [get_flow_config -quiet init_physical_files lef_files]] && \
             [llength [get_flow_config -quiet init_physical_files oa_ref_libs]])" "The read_physical specification is incomplete in setup.yaml.  Please specify either lef_files or oa_ref_libs."
      #- check that lef_files are readable by user
      if {[llength [get_flow_config -quiet init_physical_files lef_files]]} {
        foreach file [get_flow_config -quiet init_physical_files lef_files] {
          check "[file exists $file] && [file readable $file]" "The file: $file was not found or is not readable for init_physical_files lef_files section in setup.yaml"
        }
      }
    } else {
      check "[llength [get_flow_config -quiet init_physical_files lef_files]] || [llength [get_flow_config -quiet init_physical_files oa_ref_libs]]" "The read_physical specification is incomplete in setup.yaml. Please specify either lef_files or oa_ref_libs."
    }
  }}
}

##############################################################################
# STEP read_netlist
##############################################################################
create_flow_step -name read_netlist -owner cadence {
  read_netlist [get_flow_config init_netlist_files]
} -check {
  apply {{} {
    check "[llength [get_flow_config -quiet init_netlist_files]]" "The init_netlist_file specification is incomplete in setup.yaml"
    foreach file [get_flow_config -quiet init_netlist_files] {
      check "[file exists $file] && [file readable $file]" "The file: $file was not found or is not readable for init_netlist_file section in setup.yaml"
    }
  }}
}

##############################################################################
# STEP read_power_intent
##############################################################################
create_flow_step -name read_power_intent -owner cadence {
  if {![string is space [get_flow_config -quiet init_power_intent_files 1801]]} {
    read_power_intent -1801 [get_flow_config init_power_intent_files 1801]
  }
  if {![string is space [get_flow_config -quiet init_power_intent_files cpf]]} {
    read_power_intent -cpf [get_flow_config init_power_intent_files cpf]
  }
} -check {
  apply {{} {
    #check "[llength [get_flow_config -quiet init_power_intent_files]]" "The init_power_intent_files specification is incomplete in setup.yaml"
    if {![string is space [get_flow_config -quiet init_power_intent_files cpf]]} {
      foreach file [get_flow_config -quiet init_power_intent_files cpf] {
        check "[file exists $file] && [file readable $file]" "The CPF power_intent file: $file was not found or is not readable init_power_intent_files section in setup.yaml"
      }
    }
    if {![string is space [get_flow_config -quiet init_power_intent_files 1801]]} {
      foreach file [get_flow_config -quiet init_power_intent_files 1801] {
        check "[file exists $file] && [file readable $file]" "The 1801 power_intent file: $file was not found or is not readable init_power_intent_files section in setup.yaml"
      }
    }
  }}
}

##############################################################################
# STEP run_init_design
##############################################################################
create_flow_step -name run_init_design -owner cadence -write_db {
  <%? {init_ground_nets} return [list set_db init_ground_nets [get_flow_config init_ground_nets]] %>
  <%? {init_power_nets} return [list set_db init_power_nets [get_flow_config init_power_nets]] %>
  
  init_design
}

##############################################################################
# STEP commit_power_intent
##############################################################################
create_flow_step -name commit_power_intent -owner cadence {
  if {[join [dict values [get_db init_power_intent_files]]] ne {}} {
    #- commit power intent rules
    commit_power_intent
  }
}

#===============================================================================
# Common flow_steps for tool init
#===============================================================================

##############################################################################
# STEP init_innovus_yaml
##############################################################################
create_flow_step -name init_innovus_yaml -owner cadence {
  # Design attributes  [get_db -category design]
  #-------------------------------------------------------------------------------
  <%? {design_process_node} return [list set_db design_process_node [get_flow_config design_process_node]] %>
  <%? {design_tech_node} return [list set_db design_tech_node [get_flow_config design_tech_node]] %>
  <%? {routing_layers top} return [list set_db design_top_routing_layer [get_flow_config routing_layers top]] %>
  <%? {routing_layers bottom} return [list set_db design_bottom_routing_layer [get_flow_config routing_layers bottom]] %>
  <%? {design_flow_effort} return [list set_db design_flow_effort [get_flow_config design_flow_effort]] %>
  <%? {design_power_effort} return [list set_db design_power_effort [get_flow_config design_power_effort]] %>
  set_db design_early_clock_flow        true
  
# Timing attributes  [get_db -category timing && delaycalc]
#-------------------------------------------------------------------------------
set_db timing_analysis_cppr           both
set_db timing_analysis_type           ocv
<%? {timing_analysis_aocv} return [list set_db timing_analysis_aocv [get_flow_config timing_analysis_aocv]] %>
<%? {timing_analysis_socv} return [list set_db timing_analysis_socv [get_flow_config timing_analysis_socv]] %>

# Extraction attributes  [get_db -category extract_rc]
#-------------------------------------------------------------------------------
if {[is_flow -after route.block_finish]} {
  set_db delaycal_enable_si           true
  set_db extract_rc_engine            post_route
}

# Tieoff attributes  [get_db -category add_tieoffs]
#-------------------------------------------------------------------------------
<%? {add_tieoffs_cells} return [list set_db add_tieoffs_cells [get_flow_config add_tieoffs_cells]] %>
<%? {add_tieoffs_max_distance} return [list set_db add_tieoffs_max_distance [get_flow_config add_tieoffs_max_distance]] %>
<%? {add_tieoffs_max_fanout} return [list set_db add_tieoffs_max_fanout [get_flow_config add_tieoffs_max_fanout]] %>

# Optimization attributes  [get_db -category opt]
#-------------------------------------------------------------------------------
set_db opt_new_inst_prefix            "[get_db flow_report_name]_"
<%? {opt_leakage_to_dynamic_ratio} return [list set_db opt_leakage_to_dynamic_ratio [get_flow_config opt_leakage_to_dynamic_ratio]] %>

# Clock attributes  [get_db -category cts]
#-------------------------------------------------------------------------------
<%? {cts_target_skew} return [list set_db cts_target_skew [get_flow_config cts_target_skew]] %>
<%? {cts_target_max_transition_time top} return [list set_db cts_target_max_transition_time_top [get_flow_config cts_target_max_transition_time top]] %>
<%? {cts_target_max_transition_time trunk} return [list set_db cts_target_max_transition_time_trunk [get_flow_config cts_target_max_transition_time trunk]] %>
<%? {cts_target_max_transition_time leaf} return [list set_db cts_target_max_transition_time_leaf [get_flow_config cts_target_max_transition_time leaf]] %>

<%? {cts_buffer_cells} return [list set_db cts_buffer_cells [get_flow_config cts_buffer_cells]] %>
<%? {cts_inverter_cells} return [list set_db cts_inverter_cells [get_flow_config cts_inverter_cells]] %>
<%? {cts_clock_gating_cells} return [list set_db cts_clock_gating_cells [get_flow_config cts_clock_gating_cells]] %>
<%? {cts_logic_cells} return [list set_db cts_logic_cells [get_flow_config cts_logic_cells]] %>

# Filler attributes  [get_db -category add_fillers]
#-------------------------------------------------------------------------------
<%? {add_fillers_cells} return [list set_db add_fillers_cells [get_flow_config add_fillers_cells]] %>

# Routing attributes  [get_db -category route]
#-------------------------------------------------------------------------------
<%? {route_design_antenna_cell_name} return [list set_db route_design_antenna_diode_insertion true] %>
<%? {route_design_antenna_cell_name} return [list set_db route_design_antenna_cell_name [get_flow_config route_design_antenna_cell_name]] %>
} -check {
  check "!([string is true -strict [get_flow_config -quiet timing_analysis_aocv]] && [string is true -strict [get_flow_config -quiet timing_analysis_socv]])" "Select only one of timing_analysis_socv or timing_analysis_aocv"
  if {[llength [get_flow_config -quiet routing_layers top]]} {
    check "![string is integer [get_flow_config -quiet routing_layers top]]" "The route_design top layer must be an string.  Correct route_design_layers section in setup.yaml"
  }
  if {[llength [get_flow_config -quiet routing_layers bottom]]} {
    check "![string is integer [get_flow_config -quiet routing_layers bottom]]" "The route_design bottom layer must be an string.  Correct route_design_layers section in setup.yaml"
  }
}

#===============================================================================
# Common flow_steps for implementation
#===============================================================================

##############################################################################
# STEP block_start
##############################################################################
create_flow_step -name block_start -owner cadence {
}

##############################################################################
# STEP block_finish
##############################################################################
create_flow_step -name block_finish -owner cadence -write_db -categories flow {
  apply {{} {
    #- Make sure flow_report_name is reset from any reports executed during the flow
    set_db flow_report_name [get_db [lindex [get_db flow_hier_path] end] .name]
  
    #- Store non-default root attributes to metrics
    catch {report_obj -tcl} flow_root_config
    if {[dict exists $flow_root_config root:/]} {
      set flow_root_config [dict get $flow_root_config root:/]
    } elseif {[dict exists $flow_root_config root:]} {
      set flow_root_config [dict get $flow_root_config root:]
    } else {
    }
    foreach key [dict keys $flow_root_config] {
      if {[string length [dict get $flow_root_config $key]] > 200} {
        dict set flow_root_config $key "\[long value truncated\]"
      }
    }
    set_metric -name flow.root_config -value $flow_root_config
  }}
}

##############################################################################
# STEP activate_views
##############################################################################
create_flow_step -name activate_views -owner cadence {
  apply {{} {
    set db [get_db flow_starting_db]
    set flow [lindex [get_db flow_hier_path] end]
    set setup_views [get_feature -obj $flow setup_views]
    set hold_views [get_feature -obj $flow hold_views]
    set leakage_view [get_feature -obj $flow leakage_view]
    set dynamic_view [get_feature -obj $flow dynamic_view]
  
    if {($setup_views ne "") || ($hold_views ne "") || ($leakage_view ne "") || ($dynamic_view ne "")} {
      #- use read_db args for DB types and set_analysis_views for TCL
      if {([llength [get_db analysis_views]]) > 0 && \
          ([lindex $db 0] eq {tcl} || [lindex $db 0] eq {enc} && [file isfile [lindex $db 1]])} {
        set cmd "set_analysis_view"
        if {$setup_views ne ""} {
          append cmd " -setup [list $setup_views]"
        } else {
          append cmd " -setup [list [get_db [get_db analysis_views -if .is_setup] .name]]"
        }
        if {$hold_views ne ""} {
          append cmd " -hold [list $hold_views]"
        } else {
          append cmd " -hold [list [get_db [get_db analysis_views -if .is_hold] .name]]"
        }
        if {$leakage_view ne ""} {
          append cmd " -leakage [list $leakage_view]"
        } else {
          if {[llength [get_db analysis_views -if .is_leakage]] > 0} {
            append cmd " -leakage [list [get_db [get_db analysis_views -if .is_leakage] .name]]"
          }
        }
        if {$dynamic_view ne ""} {
          append cmd " -dynamic [list $dynamic_view]"
        } else {
          if {[llength [get_db analysis_views -if .is_dynamic]] > 0} {
            append cmd " -dynamic [list [get_db [get_db analysis_views -if .is_dynamic] .name]]"
          }
        }
        eval $cmd
      } elseif {[llength [get_db analysis_views]] == 0} {
        set cmd "set_flowkit_read_db_args"
        if {$setup_views ne ""} {
          append cmd " -setup_views [list $setup_views]"
        }
        if {$hold_views ne ""} {
          append cmd " -hold_views [list $hold_views]"
        }
        if {$leakage_view ne ""} {
          append cmd " -leakage_view [list $leakage_view]"
        }
        if {$dynamic_view ne ""} {
          append cmd " -dynamic_view [list $dynamic_view]"
        }
      eval $cmd
    } else {
    }
  }
}}
} -check {
  apply {{} {
    #- Check: analysis_view is defined
    foreach view [get_feature -obj [lindex [get_db flow_hier_path] end] setup_views] {
      check "[llength [get_flow_config -quiet analysis_views $view]]" "Specified setup view $view does not exist in setup.yaml"
    }
    foreach view [get_feature -obj [lindex [get_db flow_hier_path] end] hold_views] {
      check "[llength [get_flow_config -quiet analysis_views $view]]" "Specified hold view $view does not exist in setup.yaml"
    }
    check "[llength [get_feature -obj [lindex [get_db flow_hier_path] end] leakage_view]] <= 1" "Only one leakage view can be specified. Please select only one of the views specified: [get_feature -obj [lindex [get_db flow_hier_path] end] leakage_view]"
    foreach view [get_feature -obj [lindex [get_db flow_hier_path] end] leakage_view] {
      check "[llength [get_flow_config -quiet analysis_views $view]]" "Specified leakage view $view does not exist in setup.yaml"
    }
    check "[llength [get_feature -obj [lindex [get_db flow_hier_path] end] dynamic_view]] <= 1" "Only one dynamic view can be specified. Please select only one of the views specified: [get_feature -obj [lindex [get_db flow_hier_path] end] dynamic_view]"
    foreach view [get_feature -obj [lindex [get_db flow_hier_path] end] dynamic_view] {
      check "[llength [get_flow_config -quiet analysis_views $view]]" "Specified dynamic view $view does not exist in setup.yaml"
    }
  }}
}
edit_flow -before Cadence.plugin.flowkit.read_db.pre -prepend flow_step:activate_views
edit_flow -before Cadence.plugin.flowkit.read_db.post -prepend flow_step:activate_views

#===============================================================================
# Common flow_steps for reporting
#===============================================================================
if {![get_feature report_none]} {
  
  ############################################################################
  # STEP report_start
  ############################################################################
  create_flow_step -name report_start -owner cadence {
  }
  
  ############################################################################
  # STEP report_finish
  ############################################################################
  create_flow_step -name report_finish -owner cadence -categories flow {
  }
}
