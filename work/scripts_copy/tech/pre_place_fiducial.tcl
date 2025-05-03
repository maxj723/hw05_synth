##############################################################################
# STEP pre_place_fiducial
##############################################################################
create_flow_step -name pre_place_fiducial -skip_db -skip_metric -owner intel {

  ##############################################################################
  ## Places 2x local fiducials in staggered fashion
  ##############################################################################
  ## List of procs used by this script
  ##############################################################################
  #Setting up the fiducial cell from the tech_config file.
  set fidxcell [dict get $vars(INTEL_DEBUG_CELLS) pre_place local_fid ref_cell_list]
  #Creating x and y step based on modular grid-defined in tech_config  
  
  set default_xstep [dict get $vars(INTEL_DEBUG_CELLS) pre_place local_fid x_step]
  set default_ystep [dict get $vars(INTEL_DEBUG_CELLS) pre_place local_fid y_step]
  set default_strtx [dict get $vars(INTEL_DEBUG_CELLS) pre_place local_fid x_start]
  set default_strty [dict get $vars(INTEL_DEBUG_CELLS) pre_place local_fid y_start]
  set prefix [dict get $vars(INTEL_DEBUG_CELLS) pre_place local_fid prefix]
  # getting the width and height of the cell from the lib and saving it.
  scan [get_db [get_db base_cells -if .name==$fidxcell] .bbox] "{%f %f %f %f}" tmp1 tmp2 xwidth ywidth
  set fid1width $xwidth
  set fid1height $ywidth
  ## Create gaps 2 times width and height - 0.001 to provide max area for just one cell
  set gap1x [expr $fid1width + $fid1width - 0.001]
  set gap1y [expr $fid1height + $fid1height - 0.001]
  # Getting the complete area, this might not be the actual core area.
  
  set die_area [join [get_db designs .bbox] ]
  scan $die_area "%f %f %f %f" die_llx die_lly die_urx die_ury
  set cnt 0

  #####################################################
  ### Move existing placement blockage out of bounds
  ######################################################
  #######################################
  ### Start placement of fid cells
  ########################################
  set ystep_cnt 0
  set x1 [expr $die_llx + $default_strtx]
  set y1 "$die_lly"
  set x2 $x1
  while {$y1<$die_ury} {
    set y2 [expr $y1 + $default_ystep - $gap1y]
    if {$y1<$die_ury-0.001} {
      
      create_place_blockage -area "$die_llx $y1 $die_urx $y2" -name lfid_${cnt}

    }
    incr cnt
    incr ystep_cnt
    set step $default_xstep
    if {[expr $ystep_cnt%2] == 0} {
      set offx 0
    } else {
      set offx [expr $default_xstep/2]
    }
    # Offset added here to ensure that the empty areas in the placement blockage are staggered.  
    set y1 [expr $y1+$default_ystep]
    set x1 [expr $die_llx-$offx]
    if {$y1<$die_ury} {
      while {$x1<$die_urx} {
        set x2 [expr $x1 + $step - $gap1x]
        
        create_place_blockage -area "$x1 $y2 $x2 $y1" -name lfid_${cnt}
        incr cnt
        #set x1 [format %.3f [expr $x1 + $step]]
        set x1 [expr $x1 + $step]

      }
    }
  }
  # Adding the Fiducial Cell here. 
  
  add_fillers -base_cells $fidxcell -area [get_db current_design .bbox] -prefix $prefix -check_drc false -mark_fixed  
  # Removing the placement blockage  added for fid placement now.
  
  delete_obj [get_db place_blockages lfid*]
  ###################################################
  ### Restore orignal placement blockages in design
  ####################################################
  #########################EOF########################
}
