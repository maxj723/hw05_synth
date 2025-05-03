##############################################################################
# STEP create_rectilinear_routing_blockage
##############################################################################
create_flow_step -name create_rectilinear_routing_blockage -skip_db -skip_metric -owner intel {


  #Customized pullback for macros
  set pg_pullback(macro) $vars(pg_pullback_macro)
  foreach pg_layer $pg_pullback(macro) {
    set pullback_macro([lindex $pg_layer 0],macro) [lindex $pg_layer 1]
  }

  set macro_names {}
  foreach macro  [ get_db insts -if {.base_cell.base_class == block || .base_cell.base_class == pad}] {
    set name ""
    set topPinLayer ""
    set  topPinLayerNo ""
    set signal_routing_layers ""
    set name [get_db $macro .base_cell.name]
    lappend macro_names $name
    set topPinLayer [lindex [lsort -unique -dictionary -decreasing [ get_db [get_db $macro .base_cell.obs_layer_shapes.layer -if {.name == m*}] .name ]] 0]
    set topPinLayerNo [regsub {^m} $topPinLayer {}]
    for { set i [get_db [get_db layers [get_flow_config routing_layers bottom]] .route_index] } { $i <= $topPinLayerNo } { incr i } {
      lappend signal_routing_layers m$i
    }
    
    if { $macro != ""} {
      foreach layer $signal_routing_layers {
        set pins [get_db [get_db  $macro -if  .pins.base_pin.physical_pins.layer_shapes.layer.name==$layer] .pins.base_pin.physical_pins.layer_shapes.shapes.rect]
        if { $pins == ""} {
          create_route_blockage -rects [get_db $macro .overlap_rects] -name route_macro_blockage_$layer -layers $layer
        } else { 
          set pins_shape [get_transform_shapes -inst $macro -local_pt [get_db [get_db  $macro -if  .pins.base_pin.physical_pins.layer_shapes.layer.name==$layer] .pins.base_pin.physical_pins.layer_shapes.shapes.rect]]
          set macro_boxes  [get_db $macro .overlap_rects ]
          set shape_y [get_computed_shapes [get_db $macro_boxes ]]
          set ss  [get_computed_shapes -output rect $shape_y ANDNOT $pins_shape ]
          foreach  box $ss {
            create_route_blockage -rects $box -name route_macro_blockage_$layer -layers $layer  
          }
        }	
      }
      set_db  add_stripes_use_exact_spacing true
      foreach layer $signal_routing_layers {
        set pins [get_db [get_db  $macro -if  .pins.base_pin.physical_pins.layer_shapes.layer.name==$layer] .pins.base_pin.physical_pins.layer_shapes.shapes.rect]
        set pullback_macro_expand  $pullback_macro([lindex $layer 0],macro)
        if { $pins == ""} {
          set macro_boxes [get_computed_shapes [get_db $macro .overlap_rects] ]
          foreach macro_box $macro_boxes {
            if { [get_db [get_db layers $layer] .direction] == "vertical" } {
              set new_rect [get_computed_shapes $macro_box SIZEY $pullback_macro_expand]
            } elseif { [get_db [get_db layers $layer] .direction] == "horizontal" } {
              set new_rect [get_computed_shapes $macro_box SIZEX $pullback_macro_expand]
            }
            create_route_blockage -name route_macro_blockage_expand_$layer -layers $layer -spacing 0.000 -rect $new_rect
          }
        } else {
          set pins_shape [get_transform_shapes -inst $macro -local_pt [get_db [get_db  $macro -if  .pins.base_pin.physical_pins.layer_shapes.layer.name==$layer] .pins.base_pin.physical_pins.layer_shapes.shapes.rect]]
          set macro_boxes  [get_db $macro .overlap_rects ]
          set shape_y [get_computed_shapes [get_db $macro_boxes ]]
          set ss  [get_computed_shapes -output rect $shape_y ANDNOT $pins_shape ]
          foreach macro_box $ss {
            if { [get_db [get_db layers $layer] .direction] == "vertical" } {
              set new_rect [get_computed_shapes $macro_box SIZEY $pullback_macro_expand]
            } elseif { [get_db [get_db layers $layer] .direction] == "horizontal" } {
              set new_rect [get_computed_shapes $macro_box SIZEX $pullback_macro_expand]
            }
            create_route_blockage -name route_macro_blockage_expand_$layer -layers $layer -spacing 0.000 -rect $new_rect
          }
        }           
      }
    }
  }
}
