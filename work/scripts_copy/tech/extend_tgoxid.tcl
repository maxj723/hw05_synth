##############################################################################
# STEP extend_tgoxid
##############################################################################


# find out stdcell placement area
create_flow_step -name extend_tgoxid -skip_db -skip_metric -owner intel {

  if {$vars(INTEL_LIB_TYPE) == "7t108" || $vars(INTEL_LIB_TYPE) == "6t108"} {
    puts "extend_tgoxid proc is not required for 108pp"
  } elseif {$vars(INTEL_LIB_TYPE) == "7t144"} {
    set die_bndry [get_computed_shapes -output polygon [get_db designs .boundary ]]
    set no_macro_gm $die_bndry
    set all_macro_cells [get_db insts -if {.base_cell.class == block|| .base_cell.base_class == pad}]


    #set no_macro_gm [list $no_macro_gm]
    set bnd [list [get_computed_shapes $no_macro_gm ]]
    set bnd2 ""
    foreach no_mac_gm $no_macro_gm {
      set no_mac_gm [list $no_mac_gm]
      set bndtemp0 [list [get_computed_shapes $no_mac_gm SIZEX -0.577 SIZEY -0.631]]
      lappend bnd2 [get_computed_shapes $bnd ANDNOT $bndtemp0]
    }
    split $bnd2
    set bnd2 [join $bnd2]

    set new_list ""
    foreach bnd_sub $bnd2 {
      set bound_cells [get_obj_in_area -areas $bnd_sub -obj_type inst]
      foreach m $bound_cells {
        if {[lsearch $all_macro_cells $m ] < 0} {
          lappend new_list  $m }  }
    }


    foreach bnd_sub $bnd2 {
      set bound_cells [get_obj_in_area -areas $bnd_sub -obj_type inst]
      if { [llength $bound_cells] > 0 } {
        foreach cell $new_list {
          set bbox_gm [get_db $cell .bbox]
          set bnd_sized [get_computed_shapes $bbox_gm SIZEX 0.288 SIZEY 0.2925]
	        foreach one_each $bnd_sized {
            create_shape -rect  $one_each -layer TGOXID
	        }
        }
      }
    }


    set bnd2 ""
    set all_macro_cells [get_db insts -if {.base_cell.class == block || .base_cell.base_class == pad}]



    set all_macro_boxes ""
    set no_macro_gm ""

    if {$all_macro_cells ne ""} {
      foreach macro_cells $all_macro_cells {
        lappend all_macro_boxes [get_computed_shapes -output polygon [get_db $macro_cells .overlap_rects]]
      }
      foreach macro_boxes $all_macro_boxes {
        set  macro_boxes [list $macro_boxes]
        set size_macro [list [get_computed_shapes $macro_boxes SIZEX 0.577 SIZEY 0.631]]
        lappend no_macro_gm [get_computed_shapes $size_macro ANDNOT $macro_boxes]
      }
      

      split $no_macro_gm
      set bnd2 [join $no_macro_gm]

      set new_list ""
      foreach bnd_sub $bnd2 {
        set bound_cells [get_obj_in_area -areas $bnd_sub -obj_type inst]
        foreach m $bound_cells {
          if {[lsearch $all_macro_cells $m ] < 0} {
            lappend new_list  $m }  }
      }

      set no_macro_gm ""
      set  bnd2 ""
      set size_macro ""
      set macro_boxes ""
      foreach macro_boxes $all_macro_boxes {
        set  macro_boxes [list $macro_boxes]
        set size_macro [list [get_computed_shapes  $macro_boxes SIZEX 0.721 SIZEY 1.26]]
        lappend no_macro_gm [get_computed_shapes $size_macro ANDNOT $macro_boxes]
      }
      
      split $no_macro_gm
      set bnd2 [join $no_macro_gm]

      set new_list ""
      foreach bnd_sub $bnd2 {
        set bound_cells [get_obj_in_area -areas $bnd_sub -obj_type inst]
        foreach m $bound_cells {
          if {[lsearch $all_macro_cells $m ] < 0} {
            lappend new_list  $m }  }
      }

      set new_list [lsort -u $new_list]

      set new_list_1 ""
      foreach bnd_sub $bnd2 {
        set bound_cells [get_obj_in_area -areas $bnd_sub -obj_type inst]
        if { [llength $bound_cells] > 0 } {
          foreach cell $new_list {
            set bbox_gm [get_db $cell .bbox]
            set bnd_sized [get_computed_shapes $bbox_gm SIZEX 0.288 SIZEY 0.2925]
            foreach one_each $bnd_sized {
	            create_shape -rect  $one_each -layer TGOXID
            }
          }
        }
      }

    }

    ####for nwell creation#####

    set die_bndry [get_computed_shapes -output polygon [get_db designs .boundary ]]
    set all_macro_cells [get_db insts -if {.base_cell.class == block || .base_cell.base_class == pad}]
    set all_macro_boxes ""
    set no_macro_gm ""

    set boxx ""

    if {$all_macro_cells ne ""} {
      foreach macro_cells $all_macro_cells {
        lappend all_macro_boxes [get_computed_shapes -output polygon [get_db $macro_cells .overlap_rects]]
      }
      foreach macro_boxes $all_macro_boxes {
        lappend no_macro_gm [get_computed_shapes $die_bndry ANDNOT $macro_boxes]
      }


    } else {
      set no_macro_gm $die_bndry
    }

    ##get lower bottom####
    set bnd ""
    set bnd2 ""
    set bnd [list [get_computed_shapes [list $no_macro_gm]]]
    foreach no_mac_gm $no_macro_gm {
      set no_mac_gm [list $no_mac_gm]
      set bndtemp0 [list [get_computed_shapes $no_mac_gm SIZEX -0.144 SIZEY -0.631]]
      lappend bnd2 [get_computed_shapes $bnd ANDNOT $bndtemp0]
    }

    ##get lower top####
    foreach no_mac_gm $no_macro_gm {
      set no_mac_gm [list $no_mac_gm]
      set bndtemp0 [list [get_computed_shapes $no_mac_gm   SIZEX -0.144 SIZEY -1.261]]
      lappend bnd2 [get_computed_shapes $bnd ANDNOT $bndtemp0]
    }


    set bnd2 [join $bnd2]
    set new_list ""
    foreach bnd_sub $bnd2 {
      set bound_cells [get_obj_in_area -areas $bnd_sub -obj_type inst]
      foreach m $bound_cells {
        if {[lsearch $all_macro_cells $m ] < 0} {
          lappend new_list_1  $m }  }
    }

    set full_list ""

    set cell_list "cps csb fpnr00 fpy400 fpyr00 fqnr fqy403 fqyr lrn sg ps"

    foreach list_1 $cell_list {
      set list_2 [get_object_name [get_lib_cells */b15$list_1*]]
      foreach cell $list_2 { 
        set sp [split $cell /]
        lappend full_list [lindex $sp 1]
      }
    }
    set new_list_final ""
    foreach ins $new_list_1 {
      set bse [get_db $ins .base_cell.name ]
      if { [lsearch $full_list $bse] eq -1} {
        lappend new_list_final $ins 
      }
    }



    set new_list [lsort -u $new_list_final ]

    foreach cell $new_list {
      set orientation [get_db $cell .orient]
      set ref_name [get_db $cell .base_cell.name]
      if {$orientation ne "mx" && $orientation ne "r180" && $orientation ne "my" && $orientation ne "r0"} {
        continue
      }
      if {$ref_name eq $vars(INTEL_TAP_CELL)  } { 
        continue

      }
      if {$orientation eq "mx" || $orientation eq "r180"} {
        set bbox_gm [get_db $cell .bbox]
        set llx [get_db $cell .bbox.ll.x]
        set lly [get_db $cell .bbox.ll.y]
        set urx [get_db $cell .bbox.ur.x]
        set ury [get_db $cell .bbox.ur.y]
        foreach one_each $bbox_gm {
          create_shape -rect "[expr $llx - 0.288] [expr $lly-0.2925]  [expr $urx + 0.288] [expr $ury - 0.3375]"  -layer nwell
        }
      } else { 
        
        set bbox_gm [get_db $cell .bbox]
        set llx [get_db $cell .bbox.ll.x]
        set lly [get_db $cell .bbox.ll.y]
        set urx [get_db $cell .bbox.ur.x]
        set ury [get_db $cell .bbox.ur.y]
        #set bndtemp2    
        foreach one_each $bbox_gm {
          create_shape -rect "[expr $llx - 0.288] [expr $lly+ 0.3375] [expr $urx + 0.288] [expr $ury+ 0.2925 ]" -layer nwell
        }
      } 
    } 

  }
}



