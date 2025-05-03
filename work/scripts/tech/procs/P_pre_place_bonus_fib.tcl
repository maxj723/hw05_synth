proc P_pre_place_bonus_fib {} {
  global vars
  if {![dict exists $vars(INTEL_DEBUG_CELLS) pre_place bonus_fib ref_cell_list]} {
    P_msg_warn "Reference cell list not provided for Bonus FIB cell insertion. Skipping..."
    return
  }

  set upf_available [string is space [get_flow_config -quiet init_power_intent_files 1801]]
  if {!($upf_available) && [get_db [get_db power_domains -if {.is_always_on == true}  ] .name] == "" } {
    P_msg_error "No Power Domains found. Please check power intent properly."
    return
  } else {
    set fib_bonus_cells   [dict get $vars(INTEL_DEBUG_CELLS) pre_place bonus_fib ref_cell_list]
    set fib_bonus_start_x [dict get $vars(INTEL_DEBUG_CELLS) pre_place bonus_fib x_start]
    set fib_bonus_start_y [dict get $vars(INTEL_DEBUG_CELLS) pre_place bonus_fib y_start]
    set fib_bonus_incr_x  [dict get $vars(INTEL_DEBUG_CELLS) pre_place bonus_fib x_step]
    set fib_bonus_incr_y  [dict get $vars(INTEL_DEBUG_CELLS) pre_place bonus_fib y_step]
    set fib_bonus_prefix  [dict get $vars(INTEL_DEBUG_CELLS) pre_place bonus_fib prefix]
  
    set rowVal 0
    foreach arrayVal $fib_bonus_cells {
    set fib_bonus_cell_list($rowVal) $arrayVal
    incr rowVal
    }
  
  
    # Set tile values for calulation
    set stdcell_tile_width [get_db [get_db sites core_6T_108pp] .size.x]
    set stdcell_tile_height [get_db [get_db sites core_6T_108pp] .size.y]
  
  
    # Getting the complete area, this might not be the actual core area.
    set die_area [get_db current_design .bbox]
    set die_llx [get_db current_design .bbox.ll.x]
    set die_lly [get_db current_design .bbox.ll.y]
    set die_urx [get_db current_design .bbox.ur.x]
    set die_ury [get_db current_design .bbox.ur.y]
    set cnt 0
  
  
    #####################################################
    ### Move existing placement blockage out of bounds
    ######################################################
    set fib_bonusgarray_width 0.0
    set fib_bonusgarray_height 0.0
    
    foreach row [lsort -integer [array names fib_bonus_cell_list]] {
      set _tmp_width 0.324
      foreach c_ref $fib_bonus_cell_list($row) {
      set tmpx [get_db [get_db base_cells  $c_ref] .bbox.ll.x]
      set tmpy [get_db [get_db base_cells  $c_ref] .bbox.ll.y]
      set xwidth [get_db [get_db base_cells  $c_ref] .bbox.ur.x]
      set ywidth [get_db [get_db base_cells  $c_ref] .bbox.ur.y]
      set fib_cell_width $xwidth
      set fib_cell_height $ywidth
      set _tmp_width  [expr $_tmp_width + $fib_cell_width ]
      }
      if { $fib_bonusgarray_width < $_tmp_width } { 
        set fib_bonusgarray_width $_tmp_width 
      }
      set fib_bonusgarray_height [expr $fib_bonusgarray_height + $fib_cell_height]
    }
  
    # Need add the space for tap place on the left & right of FIB cells
    
set tap_width [get_db [get_db base_cells $vars(INTEL_TAP_CELL) ] .bbox.dx]
set tap_height [get_db [get_db base_cells $vars(INTEL_TAP_CELL) ] .bbox.dy]
    #set fib_bonusgarray_width [expr $fib_bonusgarray_width + 2.0 * $tap_width + .108 ]
    #######################################
    ### Start placement of fib cells
    ########################################
  
  
    set ystep_cnt 0
    #set y1 [expr $die_lly + $fib_bonus_start_y + $stdcell_tile_height]
    set y1 [expr $die_lly + $fib_bonus_start_y ]
    set yVal [expr $y1/($stdcell_tile_height*2)]
    set rval  [ lindex [ split $yVal "."] 1 ]
    if {$rval==5 } {
      set yOffset 0
    } else {
      set yOffset $stdcell_tile_height
    }
    set y1 [expr $y1 - $yOffset]
  
    set fib_blockages {}
    while {$y1<$die_ury} {
      set x1 [expr $die_llx + $fib_bonus_start_x]
      if {[expr $ystep_cnt%2] == 0} {
        set offx 0
      } else {
        set offx [expr $fib_bonus_incr_x/2]
      }
      set x1 [expr $x1 + $offx]
      set xstep_cnt 0
      while {$x1<$die_urx} {
        set y2 [expr $y1 + $fib_bonusgarray_height ]
        set x2 [expr $x1 + $fib_bonusgarray_width ]
        if {($y2<$die_ury-0.001) && ($x2<$die_urx-.001) } {
          #if {[format %.3f [expr fmod(($x2-.756),$vars(INTEL_TAP_GAP))] ] > [format %.3f [expr $vars(INTEL_TAP_GAP) - .54]]} {
          #  set x1_new [expr $x1 - ([format %.3f [expr fmod(($x2-.756),$vars(INTEL_TAP_GAP))]]- ($vars(INTEL_TAP_GAP) - .702)) + $offset_left]
          #  set x2_new [expr $x2 - ([format %.3f [expr fmod(($x2-.756),$vars(INTEL_TAP_GAP))]]- ($vars(INTEL_TAP_GAP) - .702)) + $offset_left]
          #} else { 
            set x1_new $x1
            set x2_new $x2
          #}
          #if { [format %.3f [expr fmod($x1_new,.108)]] == 0.054 } {
          #   set offset_left 0.054
          #} else {
          #   set offset_left 0.000
          #}
          #if { $offset_left > 0.0 } {
          # set x1_new [expr $offset_left + $x1_new]
          #   set x2_new [expr $offset_left + $x2_new]
          #}     
          if { [P_fib_check_box_overlap $x1_new $y1 $x2_new $y2 ] == 0  && [get_computed_shapes -output polygon  "$x1_new $y1 $x2_new $y2" INSIDE [get_computed_shapes -output polygon [get_db designs .boundary]]] > 0 } {
            #createPlaceBlockage -box "$x1_new $y1 $x2_new $y2" -name fib_${cnt}__default
            
            create_place_blockage -area "$x1_new $y1 $x2_new $y2" -name fib_${cnt}__default
            
            lappend fib_blockages [list "$x1_new $y1 $x2_new $y2"]
          }
        }
        incr cnt
        incr xstep_cnt
        set x1 [expr $x1+$fib_bonus_incr_x];
      }
      # Offset added here to ensure that the empty areas in the placement blockage are staggered.  
      incr ystep_cnt
      set y1 [expr $y1+ $fib_bonus_incr_y/2];
      set yVal [expr $y1/($stdcell_tile_height*2)]
      set rval  [ lindex [ split $yVal "."] 1 ]
      if {$rval==5 } {
        set yOffset 0
      } else {
        set yOffset $stdcell_tile_height
      }
      set y1 [expr $y1 - $yOffset]
    }
  
    set upf_available [string is space [get_flow_config -quiet init_power_intent_files 1801]]
    if {!($upf_available)} {
      foreach {pdNameVal bdry} [array get powerDomains] {
        set pdName [lindex [split $pdNameVal "," ] 0]
        if {$pdName!= "" && $bdry!="{}"} {
          if {![get_db power_domain:$pdName .is_default]} {
            set bboxList [get_computed_shapes -output rect $bdry]
           
            foreach bboxVal $bboxList {
              if {![regexp "0x0" $bboxVal ]} {
                set _llx [regsub "\{" [lindex  [split $bboxVal  " "] 0] "" ]
                set _lly [lindex  [split $bboxVal  " "] 1]
                set _urx [lindex  [split $bboxVal  " "] 2]
                set _ury [regsub "\}" [lindex  [split $bboxVal  " "] 3] "" ]
                set win "{[expr $_llx + 0.001] [expr $_lly + 0.018]} {[expr $_urx - 0.001] [expr $_ury - 0.018]}"
                set winVal "[expr $_llx + 0.001] [expr $_lly + 0.018] [expr $_urx - 0.001] [expr $_ury - 0.018]"
                set placeBlkgList [get_obj_in_area -areas $win -obj_type place_blockage]
                foreach blockage [lindex $placeBlkgList] {
                  set blkgName [get_db $blockage .name]
                  if {[regexp "fib_" $blkgName] } {
                    set bbox [get_db $blockage .shapes.rect]
                    delete_obj [get_db place_blockages $blkgName]
                    if { [llength [get_computed_shapes -output rect $bbox INSIDE $winVal]] > 0 } { 
                      regexp {(.*)__(.*)$} $blkgName  match a b
                      set blkgName_new $a
                      create_place_blockage -area $bbox -name ${blkgName_new}__${pdName}
                    }
                  }
                }
              }
            }
          }
        }
      }
    }


set wd [expr $vars(INTEL_WS_X)*2]
set ht [expr $vars(INTEL_WS_Y)*2]
set i 0 
set macros_list [get_db insts -if {.base_cell.base_class == block || .base_cell.base_class == pad}]
if { $macros_list != ""} {
set boxx ""
foreach macro $macros_list {
set m [ get_computed_shapes [get_db $macro .overlap_rects]]  
set boxx [get_computed_shapes  $m OR  $boxx]
set macro_boxes [get_computed_shapes [get_computed_shapes $boxx   SIZEX $wd SIZEY $ht  ] ANDNOT [get_computed_shapes $boxx  ] ] 
}


foreach win $macro_boxes {
set placeBlkgList [get_obj_in_area -area $win -obj_type place_blockage]
foreach blockage [lindex $placeBlkgList] {
                  set blkgName [get_db $blockage .name]
                  if {[regexp "fib" $blkgName] } {
                 delete_obj [get_db place_blockages $blkgName]
}
}
}
}

    ### Now insert in the fib & bonus cells at the -as_blockage location
    unset -nocomplain count
    set count 0
    foreach pblk [get_db place_blockages ] {
      set deleteInstList {}
      if { ![regexp " " [get_db $pblk .shapes.rect.ll.x]] && ![regexp " " [get_db $pblk .shapes.rect.ll.y]] &&  ![regexp " " [get_db $pblk .shapes.rect.ur.x]] && ![regexp " " [get_db $pblk .shapes.rect.ur.y]] } {
        if {[regexp "fib_" [get_db $pblk .name]]} {
          set _llx [get_db $pblk .shapes.rect.ll.x] 
          set _lly [get_db $pblk .shapes.rect.ll.y] 
          set _urx [get_db $pblk .shapes.rect.ur.x] 
          set _ury [get_db $pblk .shapes.rect.ur.y] 
  
          set tapRightX [expr $_urx + $tap_width *2  + 0.432] 
          #MV changed bonuscore site for 1222
          ### Remove the tap cells inside the area first
          unset -nocomplain rm_tap_cmds
          set win "{[expr $_llx + 0.011] [expr $_lly + 0.078]} {[expr $_urx - 0.011] [expr $_ury - 0.078]}"
          set cellInst [get_obj_in_area -areas $win -obj_type inst]
          foreach cellInst_2 [lindex $cellInst] {

            if {  $cellInst_2  != "" } {
              if {  [get_db $cellInst_2] != "" } {
                set tap [get_db $cellInst_2 .base_cell.name ]
                if {($tap eq $vars(INTEL_TAP_CELL)) && ([regexp "TAP" [get_db $cellInst_2 .name]] )} {
                  set tap_name [get_db $cellInst_2 .name]
                  set box [get_db $cellInst_2 .bbox]
                  set _llx_tap [regsub "\{" [lindex  [split $box  " "] 0] "" ]
                  set _lly_tap [lindex  [split $box  " "] 1]
                  set _urx_tap [lindex  [split $box  " "] 2]
                  set _ury_tap [regsub "\}" [lindex  [split $box  " "] 3] "" ]
                  set win_tap "{[expr $_llx_tap - 0.011] [expr $_lly_tap + 0.078]} {[expr $_urx_tap + 0.011] [expr $_ury_tap - 0.078]}"
                  set cellInst2 [get_obj_in_area -areas $win_tap -obj_type inst]
                  foreach cellInst_3 [lindex $cellInst2] {
                    set tap_name2 [get_db $cellInst_3 .name]
                    if {([get_db $cellInst_3 .base_cell.name ] eq $vars(INTEL_TAP_CELL)) && ([regexp "TAP" $tap_name2] )} {
                      if { [get_db insts $tap_name2] != "" } {
                        lappend deleteInstList  [get_db [get_db insts $tap_name2] .name]
                      }
                    }
                  } 
                  if { [get_db insts $tap_name] != "" } {
                    lappend deleteInstList  [get_db [get_db insts $tap_name] .name]
                  }
                }
              }
            }
          }
          set addTap 0
          set uniqueVioList [lsort -unique $deleteInstList]
          if { [llength $uniqueVioList] > 0 } {
            foreach instVal $uniqueVioList {
              delete_inst -inst $instVal
            }
            set addTap 1
          }
          set yVal [expr $y1/($stdcell_tile_height*2)]
          set rval  [ lindex [ split $yVal "."] 1 ]
          if {$rval==0 } {
            set orient "MX"
          } else {
            set orient "R0"
          }
      
          set loc_x $_llx 
          set loc_y $_lly
      
          #if { [format %.3f [expr fmod($loc_x,.108)]] == 0.054 } {
          #  set loc_x [expr $_llx + 0.054 ]
          #} 
          set rowHeight 0 
          foreach row [lsort -integer [array names fib_bonus_cell_list]] {
            set loc_y [expr $loc_y + $rowHeight]
            set orientStart $orient
            set col 0
            if { $addTap == 1 } {
              set curcell [format "%s_%d_r%dc%s" $fib_bonus_prefix $count $row "_garraytapleft"]
              set cell_full_name $curcell
              set module [P_get_module_name_for_power_domain_from_coord -x $_llx -y $loc_y]
              P_add_inst -cell $vars(INTEL_TAP_CELL) -inst ${module}${cell_full_name} -x $_llx -y $loc_y -ori $orient 
              #if { [format %.3f [expr fmod($tap_width,.108)]] == 0.054 } {
              #  set loc_x [expr $_llx + $tap_width + 0.054 ]
              #} else { 
              set loc_x [expr $_llx + $tap_width]
              #}
            }
            foreach c_ref $fib_bonus_cell_list($row) {
              set width_cell [get_db [get_db base_cells -if {.name == $c_ref} ] .bbox.dx]
              set rowHeight [get_db [get_db base_cells -if {.name == $c_ref} ] .bbox.dy]

              set cell_full_name ""
              set curcell [format "%s_%d_r%dc%d" $fib_bonus_prefix $count $row $col]
              set cell_full_name $curcell
              set module [P_get_module_name_for_power_domain_from_coord -x $loc_x -y $loc_y]
              P_add_inst -cell $c_ref -inst ${module}${cell_full_name} -x $loc_x -y $loc_y  -ori $orient 
              set orient $orientStart
              #if { [format %.3f [expr fmod($width_cell,.108)]] == 0.054 } {
              #  set loc_x [expr $loc_x + $width_cell + 0.054]
              #} else { 
              set loc_x [expr $loc_x + $width_cell]
              #}
              incr col
            }
       
            if { $addTap == 1 } {
              set curcell [format "%s_%d_r%dc%s" $fib_bonus_prefix $count $row "_garraytapright"]
              set cell_full_name $curcell
              set module [P_get_module_name_for_power_domain_from_coord -x $tapRightX -y $loc_y]
              P_add_inst -cell $vars(INTEL_TAP_CELL) -inst ${module}${cell_full_name} -x $tapRightX -y $loc_y -ori $orient 
            }
            if {$addTap == 1 } {
              #if { [format %.3f [expr fmod($tap_width,.108)]] == 0.054 } {
              #  set loc_x [expr $_llx + $tap_width + 0.054 ]
              #} else { 
              set loc_x [expr $_llx + $tap_width]
              #}
            } else {
              set loc_x $_llx 
              #if { [format %.3f [expr fmod($loc_x,.108)]] == 0.054 } {
              #  set loc_x [expr $_llx + 0.054 ]
              #} 
            }
            if { $orient == "R0" } {
              set orient "MX"
            } elseif { $orient == "MX" } {
              set orient "R0"
            }
          }
          incr count
        }
      }
    }
    
    
    
    delete_obj [get_db place_blockages fib_*]


    ###################################################
    ### Restore orignal placement blockages in design
    ####################################################
    

   }
}
 
