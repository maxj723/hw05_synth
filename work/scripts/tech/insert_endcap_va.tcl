##############################################################################
# STEP insert_endcap_va
##############################################################################
create_flow_step -name insert_endcap_va -owner intel {

  set upf_available [string is space [get_flow_config -quiet init_power_intent_files 1801]]
  if {!($upf_available)} {

    if {$vars(INTEL_VA_ISO_CELL) == ""} {
      P_msg_error "No VA Isolation specified , kindly set vars(INTEL_VA_ISO_CELL) in tech_config.tcl"
    }    

    set VA_ISO_HEIGHT [get_db base_cell:$vars(INTEL_VA_ISO_CELL) .bbox.length]
    set VA_ISO_WIDTH [get_db base_cell:$vars(INTEL_VA_ISO_CELL) .bbox.width]

    set va_iso_inc_offset [expr $VA_ISO_WIDTH / 2]
    set va_iso_counter 0

    # The procedure to determine the direction
    proc P_find_direction {start end} {
      set startx [lindex $start 0]
      set starty [lindex $start 1]
      set endx [lindex $end 0]
      set endy [lindex $end 1]
      if {$startx == $endx && $starty==$endy} {
        return "nochange"
      } elseif {$startx<$endx && $starty==$endy} {
        return "right"
      } elseif {$startx==$endx && $starty<$endy} {
        return "up"
      } elseif {$startx>$endx && $starty==$endy} {
        return "left"
      } elseif {$startx==$endx && $starty>$endy} {
        return "down"
      } else {
        puts "Cannot determine direction"
      }
    }

    #
    # Walk though the boundary in clockwise direction
    # Find the direction and the previous direction, and determine placement of vertical/horizontal/corner/inside VA Isolation cells
    #

    set type [lindex [split [get_db current_design .name] _] end]
    set pd_names [get_db power_domains .name]
    array unset powerDomains {}

    ## Checking if power domain overlaps with floorplan boundry

    foreach power_dmn $pd_names {
      if { $power_dmn != ""} {
        if {![get_db power_domain:$power_dmn .is_default]} {
          if { [get_db [get_db power_domains $power_dmn] .group.rects] == ""} {
            P_msg_warn "No physical location found for power domain $power_dmn. Please fix unless this is a virtual domain"
            continue
          }
          #set box_area_dmn [dbGet [dbGet -p2 top.fPlan.groups.pd.name $power_dmn].boxes]
          set box_area_dmn [get_db [get_db power_domains $power_dmn ] .group.rects]
          set boundary ""
          foreach  box_dmn $box_area_dmn {
            set nb [lindex [get_computed_shapes -output polygon $box_dmn NOHOLES] 0]
            set nb_chk [llength $nb]
            if { $nb_chk ==4 } {
              set boundary1 "{[lindex $nb 2]} {[lindex $nb 1]} {[lindex $nb 0]} {[lindex $nb 3]} {[lindex $nb 2]}"
            } else {
              set m  "$nb \{[lindex $nb 0]\} "
              set boundary1 [lreverse $m]
            }
            lappend boundary $boundary1
          }
          array set powerDomains [list $power_dmn  $boundary]
        }
      }
    }


    set domain_cntr 0
    foreach {pdName boundary} [array get powerDomains] {
      incr domain_cntr }
    puts  "Number of domain or domains:$domain_cntr"

    #check for shared boundary points between domains
    set ct 0
    foreach {pdName boundary} [array get powerDomains] {
      foreach boundary1 $boundary {
        incr ct
        set bndry($ct) $boundary1
      }
    }
    list common_pts {}
    set shared [lsort -unique powerDomains]

    #main VA Isolation insertion algorithm
    foreach {pdName boundary1} [array get powerDomains] {
      foreach boundary $boundary1 {
        # these are globals (used by P_place_halo as globals)
        #set va_iso_counter 0
        set va_iso_orient_N ""
        set va_iso_orient_FN ""
        set va_iso_orient_S ""
        set va_iso_orient_FS ""

        set o ""

        if { $pdName != ""} {
          if {![get_db power_domain:$pdName .is_default]} {
            #get name of module
            #set module "[lindex [dbGet [dbGet -p2 top.fPlan.groups.pd.name $pdName].members.name] end]/"
            set module "[lindex [get_db [get_db power_domains $pdName ] .group.members.name] end]/"
          }  
        }
        # first determine the direction from the last point to the first point
        set startpoint "{[lindex $boundary end-1]}"
        set endpoint "{[lindex $boundary 0]}"
        set prev_direction [P_find_direction $startpoint $endpoint]
        puts "Initial startpoint $startpoint"
        puts "Initial endpoint $endpoint"
        puts "Initial direction is $prev_direction"


        set startpoint [lindex $boundary 0]
        foreach endpoint $boundary {
          #find the direction from $startpoint to $endpoint
          #is it going up, down, left, or right
          set direction [P_find_direction $startpoint $endpoint]
          set startx [lindex $startpoint 0]
          set starty [lindex $startpoint 1]
          set endx [lindex $endpoint 0]
          set endy [lindex $endpoint 1]

          #compare startpoint and endpoint to shared boundary points
          set bndry_end "false"
          set bndry_start "false"
          foreach pt $shared {
            if {$startpoint == $pt} {
              set bndry_start "true"
              puts "Startpoint is the same as a boundary point: $pt"
            } elseif {$endpoint == $pt} {
              set bndry_end "true"
              puts "Endpoint is the same as a boundary point: $pt"
            }
          }
          set bndry_edge [expr {$bndry_start && $bndry_end}]

          puts "Current startpoint ($startx, $starty)"
          puts "Current endpoint ($endx, $endy)"
          puts "Previous direction is $prev_direction"
          puts "Current direction is $direction"

          if {$direction == "nochange"} {
            #Do nothing, move on!
            puts "Ignore VA Iso cell insertion"
          } elseif {$direction == "left"} {
            if {$prev_direction == "down"} {
              #              v down
              #              |
              #              |
              #              |
              #   HHHHHHHHHHC|
              #  <-----------+
              # left
              incr va_iso_counter
              set x [expr $startx-$VA_ISO_WIDTH-$VA_ISO_WIDTH]
            } elseif {$prev_direction == "up"} {
              #
              #   HHHHHHHHHHHHI
              #  <-----------+V
              # left         |
              #              |
              #              |
              #              ^up
              # This is a rectilinear inside corner
              incr va_iso_counter
              set x [expr $startx-$VA_ISO_WIDTH-$va_iso_inc_offset]
            } else {
              puts "I DONT KNOW WHAT THIS IS : direction $direction, previous direction $prev_direction"
            }
            set prev_direction $direction
          } elseif {$direction == "down"} {
            if {$prev_direction == "right"} {
              # right>-----------+
              #                 C|
              #                 V|
              #                 V|
              #                 V|
              #                  v down
              if {$bndry_start} {
                ##addInst -cell $vars(INTEL_VA_ISO_CELL) -inst ${module}va_iso_v$va_iso_counter -loc [expr $startx-$VA_ISO_WIDTH] [expr $starty-$VA_ISO_HEIGHT] -status fixed -ori $o
              } else {
                ###Adding the inside Corner cell on right upper
                create_inst -cell $vars(INTEL_VA_ISO_CELL) -inst ${module}upf_va_iso_$va_iso_counter -location [expr $startx-$VA_ISO_WIDTH] [expr $starty-$VA_ISO_HEIGHT] -status fixed -orient MY
                incr va_iso_counter
                ###Adding the outside corner cell on right upper
                set p 0
                foreach pwr_domain [get_db power_domains .name] {
                  set k ""
                  set k [get_computed_shapes "{ $startx [expr $starty - $VA_ISO_HEIGHT] [expr $startx + 0.05] [expr $starty - $VA_ISO_HEIGHT + 0.05]}" AND [get_db power_domain:$pwr_domain .group.rects]] 
                  if {$k != ""} {
                    if { $p == 0} {		
                      set module_out "[lindex [get_db [get_db [get_db power_domains $pwr_domain] .group.members] .name] end]/"

                      set p 1	
                      create_inst -cell $vars(INTEL_VA_ISO_CELL) -inst ${module_out}out_upfva_iso_$va_iso_counter -location $startx [expr $starty-$VA_ISO_HEIGHT] -status fixed -orient R0
                    }
                  } else {}
                }
              }
              incr va_iso_counter
              set y [expr $starty-$VA_ISO_HEIGHT-$VA_ISO_HEIGHT]
            } elseif {$prev_direction == "left"} {
              #    IH
              #    V+-----------<left
              #    V|
              #    V|
              #    V|
              #    V|
              #     v down
              # This is a rectilinear inside corner
              incr va_iso_counter
              set y [expr $starty-$VA_ISO_HEIGHT]
            } else {
              puts "I DONT KNOW WHAT THIS IS : direction $direction, previous direction $prev_direction"
            }
            if {!$bndry_edge} {
              while {$y >= [expr $endy-0.001]} {
                ###Adding the cells on the right side for inside and outside
                create_inst -cell $vars(INTEL_VA_ISO_CELL) -inst ${module}upfva_iso_$va_iso_counter -location [expr $startx-$VA_ISO_WIDTH] $y -status fixed -orient MY
                incr va_iso_counter
                set p 0
                foreach pwr_domain [get_db power_domains .name] {
                  set k ""
                  set k [get_computed_shapes "{ $startx  $y [expr $startx + 0.05] [expr $y  + 0.05]}" AND [get_db power_domain:$pwr_domain .group.rects]] 
                  if {$k != ""} {
                    if {$p == 0} { 	
                      set module_out "[lindex [get_db [get_db [get_db power_domains $pwr_domain] .group.members] .name] end]/"
                      set p 1		
                      create_inst -cell $vars(INTEL_VA_ISO_CELL) -inst ${module_out}out_upfva_iso_$va_iso_counter -location $startx $y -status fixed -orient R0
                    } 	
                  } else {}
                }
                incr va_iso_counter
                set y [expr $y-$VA_ISO_HEIGHT]
              }
            }
            set prev_direction $direction
          } elseif {$direction == "right"} {
            if {$prev_direction == "up"} {
              # +-----------> right
              # |CHHHHHHHHHH
              # |
              # |
              # |
              # ^up
              #puts "Orientation should be MX, and is $o"
              incr va_iso_counter
              set x [expr $startx+$VA_ISO_WIDTH]
            } elseif {$prev_direction == "down"} {
              #  v down
              #  |
              #  |
              #  |
              #  |
              # V+----------> right
              # IHHHHHHHHHHH
              # This is a rectilinear inside corner
              incr va_iso_counter
              set x [expr $startx+$va_iso_inc_offset]
            } else {
              puts "I DONT KNOW WHAT THIS IS : direction $direction, previous direction $prev_direction"
            }
            set prev_direction $direction
          } elseif {$direction == "up"} {
            if {$prev_direction == "left"} {
              #  ^ up
              #  |V
              #  |V
              #  |V
              #  |C
              #  +-----------<left
              if {$bndry_start} {
              } else {
                ##Adding the last corner cell in ll corner. inside and outside
                create_inst -cell $vars(INTEL_VA_ISO_CELL) -inst ${module}upfva_iso_$va_iso_counter -location $startx $starty -status fixed -orient R0
                incr va_iso_counter
                set p 0
                foreach pwr_domain [get_db power_domains .name] {
                  set k ""
                  set k [get_computed_shapes "{ [expr $startx - $VA_ISO_WIDTH] $starty [expr $startx -$VA_ISO_WIDTH + 0.05] [expr $starty + 0.05]}" AND [get_db power_domain:$pwr_domain .group.rects]] 
                  if {$k != ""} {
                    if { $p == 0 } {
                      set module_out "[lindex [get_db [get_db [get_db power_domains $pwr_domain] .group.members] .name] end]/"
                      set p 1		
                      create_inst -cell $vars(INTEL_VA_ISO_CELL) -inst ${module_out}out_upfva_iso_$va_iso_counter -location [expr $startx - $VA_ISO_WIDTH]  $starty -status fixed -orient MY
                    }
                  } else {}
                }
              }
              incr va_iso_counter
              set y [expr $starty+$VA_ISO_HEIGHT]
            } elseif {$prev_direction == "right"} {
              #                  ^ up
              #                  |V
              #                  |V
              #                  |V
              #  right>----------+V
              #                  HI
              # This is a rectilinear inside corner
              incr va_iso_counter
              set y $starty
            } else {
              puts "I DONT KNOW WHAT THIS IS : direction $direction, previous direction $prev_direction"
            }
            if {!$bndry_edge} {
              while {$y <= [expr $endy-$VA_ISO_HEIGHT+0.001]} {
                ##Adding the cells on ll side.inside and outside
                create_inst -cell $vars(INTEL_VA_ISO_CELL) -inst ${module}upfva_iso_$va_iso_counter -location $startx  $y  -status fixed -orient R0
                incr va_iso_counter
                set p 0 
                foreach pwr_domain [get_db power_domains .name] {
                  set k ""
                  set k [get_computed_shapes "{ [expr $startx - $VA_ISO_WIDTH] $y [expr $startx -$VA_ISO_WIDTH + 0.05] [expr $y + 0.05]}" AND [get_db power_domain:$pwr_domain .group.rects]] 
                  if {$k != ""} {
                    if { $p ==0 } {
                      set module_out "[lindex [get_db [get_db [get_db power_domains $pwr_domain] .group.members] .name] end]/"	
                      create_inst -cell $vars(INTEL_VA_ISO_CELL) -inst ${module_out}out_upfva_iso_$va_iso_counter -location [expr $startx - $VA_ISO_WIDTH] $y -status fixed -orient MY
                      set p 1
                    }
                  } else {}
                }
                incr va_iso_counter
                set y [expr $y+$VA_ISO_HEIGHT]
                #flip the orientation every other row
              }
            }
            set prev_direction $direction
          } else {
            puts "Cannot interpret direction \"$direction\""
          }
          set startpoint $endpoint
        }

        #setPlaceMode -allowBorderPinAbut true
        set_db place_detail_allow_border_pin_abut true

        if {[info exists pchkOverlapFixedList]} {
          unset pchkOverlapFixedList
        }
        if {[info exists pchkOutOfCoreFixedList]} {
          unset pchkOutOfCoreFixedList
        }
        if {[info exists pchkNotOfFenceFixedList]} {
          unset pchkNotOfFenceFixedList
        }

        check_place -no_halo vio.rpt
        source  vio.rpt
        if {[info exists pchkOverlapFixedList]} {
          foreach k $pchkOverlapFixedList {
            if { [string match *out_upfva_iso_* $k] } {
              delete_inst  -inst $k
            } else {}
          }
        }
        if {[info exists pchkOutOfCoreFixedList]} {
          foreach k $pchkOutOfCoreFixedList {
            if { [string match *out_upfva_iso_* $k] } {
              delete_inst  -inst $k
            }
          }
        }

        if {[info exists pchkNotOfFenceFixedList]} {
          unset pchkNotOfFenceFixedList
        }
        check_place -no_halo vio.rpt
        source  vio.rpt
        # Update pd for not-of fence VA Isolation cell violations
        if {[info exists pchkNotOfFenceFixedList]} {
          foreach k $pchkNotOfFenceFixedList {
            if {[string match *va_iso* $k]} {
              foreach pd [get_db [get_db power_domains -if {.is_default == false }] .name] {
                if { [get_computed_shapes -output polygon [get_db inst:$k .bbox] AND [get_computed_shapes -output polygon [get_db power_domain:$pd .group.rects]]] != ""} {
                  
                  update_group -name $pd -objs $k 
                }
              }
            }
          }
        }

        if {[info exists pchkOverlapFixedList]} {
          unset pchkOverlapFixedList
        }
        check_place -no_halo vio.rpt
        source  vio.rpt
        if {[info exists pchkOverlapFixedList]} {
          foreach k $pchkOverlapFixedList {
            if { [string match *upfva_iso_* $k] } {
              delete_inst  -inst $k
            }
          }
        }

        set_db place_detail_allow_border_pin_abut false
      }
    }


    ### Delete overlap cells
    #suppressMessage ENCSYC-296

    set_db place_detail_allow_border_pin_abut true
    check_place
    set_db place_detail_allow_border_pin_abut false

    ## unset del_cells  if you are running again and again

  }

}
