##############################################################################
# NAME 			:	tech_config.7t108.tcl
#
# SUMMARY 		:	File that contains variable needed for tech modules and each tech contour
################################################################################

#################################################################################
#################################################################################
#TOOL SPECIFIC DATA
#################################################################################
#################################################################################

set tool [lindex [split [info nameofexecutable] "/"] end]

#################################################################################
#################################################################################
#PROCESS SPECIFIC DATA
#################################################################################
#################################################################################
set vars(INTEL_FDK_LIB)                 "b0m"
set vars(INTEL_DOTP)                    "dot4"
set vars(INTEL_LIB_TYPE)                "6t108"
set vars(INTEL_TRACKPATTERN)            "tp0"
set vars(INTEL_FEATURE)                 ""
set vars(INTEL_LIB_VENDOR)              ""

set vars(INTEL_MD_GRID_X)               "0.108"
set vars(INTEL_MD_GRID_Y)               "0.540"
# White space number
set vars(INTEL_WS_X)                    "0.432"
set vars(INTEL_WS_Y)                    "0.540"
#set vars(INTEL_WS_Y) 					"1.26"
set INTEL_WS_TO_WS_SPACING              1.000
#width spacing required for tap cell insertion => add_tap_cells.tcl
set vars(INTEL_WIDTH_SPACING_LIST)      "30 3 80 4 180 12"



#################################################################################
#################################################################################
#PROJECT SPECIFIC DATA 
#################################################################################
#################################################################################

#######################################################################
# Local fiducial and bonus FIB cells
#  Note: Local fiducials are inserted before and after place step by default.
#        Bonus FIB cells are only preplaced
#######################################################################
set vars(INTEL_DEBUG_CELLS) [dict create {*}{
  pre_place {
    local_fid {
      ref_cell_list {b0mqfd1x2an1nnpx5}
      x_step  {50.22}    y_step  {50.4}
      x_start {25.11}   y_start {11.97}
      prefix  {local_fiducial_preplace}
    }
    bonus_fib {
      ref_cell_list {
      {b0mqgbar1an1n64x5}
      {b0mqbnna2bh1n16x5 b0mqbnno2bh1n12x5 b0mqbnbf1bh1n32x5 b0mqbnin1bh1n40x5}
      {b0mqbnff4bh1n08x5 b0mqbnlf4bh1n08x5}
      {b0mqbnna2bh1n16x5 b0mqbnno2bh1n12x5 b0mqbnbf1bh1n32x5 b0mqbnin1bh1n40x5}
      {b0mqgbar1an1n64x5}
      {b0mqgbar1an1n64x5}
      }
      x_step {151.2}    y_step {108}
      x_start {75.6}   y_start {31.5}
      prefix  {garrayfib}
      width_scale {1.5} height_scale {2.0}
    }
  }
}]

#######################################################################
# TAP INSERT
#######################################################################
set vars(INTEL_TAP_CELL)  		"$vars(INTEL_FDK_LIB)ztpn00an1n08x5"
set vars(INTEL_TAP_GAP)         77.544 

#######################################################################
#LOW POWER FLOW CELLS/ ISOLATION CELL  
#######################################################################
set vars(INTEL_VA_ISO_CELL)             "b0mzdnnvian1d03x5"


#######################################################################
#SPARE CELLS / TIE CELLS  
#######################################################################
set vars(INTEL_SPARECELLS)              "$vars(INTEL_FDK_LIB)nand02al1n16x5 $vars(INTEL_FDK_LIB)nand02al1n16x5 $vars(INTEL_FDK_LIB)nand02al1n32x5 $vars(INTEL_FDK_LIB)nor002al1n08x5 $vars(INTEL_FDK_LIB)nor002al1n08x5 $vars(INTEL_FDK_LIB)nor002al1n12x5 $vars(INTEL_FDK_LIB)inv000al1n16x5 $vars(INTEL_FDK_LIB)inv000al1n08x5"
set vars(INTEL_TIECELLS)                [get_flow_config add_tieoffs_cells]

#######################################################################
#TILES  
#######################################################################
set vars(INTEL_STDCELL_TILE)                    "core_6T_108pp"
set vars(INTEL_STDCELL_BONUS_GATEARRAY_TILE)    "bonuscore_6T_108pp"
set vars(INTEL_STDCELL_CORE2H_TILE)             "core2h_6T_108pp"


#######################################################################
#VT TYPES
#######################################################################
set vars(INTEL_ENABLE_VT_TYPES) {lvt lplvt nom ulp ulvt lp hp}
set vars(INTEL_LIB_STRING) "lib224_b0m_6t_108pp"

#######################################################################
#MAP FILES
#######################################################################
set vars(INTEL_QRC_LAYER_MAP)           "$env(INTEL_PDK)/extraction/qrc/asic/$env(LAYERSTACK)/asic.qrc.map"
set vars(INTEL_OAS_LAYER_MAP)           [get_flow_config layer_map]
