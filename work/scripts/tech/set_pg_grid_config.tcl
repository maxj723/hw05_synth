##############################################################################
# STEP set_pg_grid_config
##############################################################################


# P/G grid configurations for P1222.2 dot process  cell library tp0 track pattern.

# NOTE: See create_pg_grid.tcl for syntax of INTEL_PG_GRID_CONFIG var.
set INTEL_POWER_PLAN_2_PG_GRID_CONFIG(mesh_nonupf) {
   m2 {
    pullback 0.08
    power {
      pitch 1.08
      offset,width {
        0  0.044
      }
    }
    ground {
      pitch 1.08
      offset,width {
        0.540  0.044
      }
    }
  }
  m3 {
    pullback 0.08
    ground {
      pitch 1.08
      offset,width {
        0.00 0.044
      }
    }
    power {
      pitch 1.08
      offset,width {
        0.54  0.044
      }
    }
  }
  m4 {
    pullback 0.08
    power {
      pitch 1.08
      offset,width {
        0.00  0.044
      }
    }
    ground {
      pitch 1.08
      offset,width {
        0.54  0.044
      }
    }
  }
  m5 {
    pullback 0.08
    ground {
      pitch 1.08
      offset,width {
        0.00  0.044
      }
    }
    power {
      pitch 1.08
      offset,width {
        0.54  0.044
      }
    }
  }
  m6 {
    pullback 0.080
    ground {
      pitch 2.160
      offset,width {
        0.00  0.160
      }
    }
    power {
      pitch 2.160
      offset,width {
        1.080  0.160
      }
    }
  }
  m7 {
    pullback 0
    ground {
      pitch 4.32
      offset,width {
        0.00  0.180
      }
    }
    power {
      pitch 4.32
      offset,width {
        2.16  0.180
      }
    }
  }
  m8 {
    pullback 0
    ground {
      pitch 4.32
      offset,width {
        0.00  0.180
      }
    }
    power {
      pitch 4.32
      offset,width {
        2.16  0.180
      }
    }
  }
}

# TODO: Check if need extra m6 power_va_primary, i.e. 2 * 0.108 width per 3.192 pitch, to match m6 ground.
# TODO: Check if even necessary for m4 & m5 power_va_aon, since they compromise m4 & m5 power_va_primary, 3 instead 6 per 6.384 & 1 instead 2 per 3.36 pitches respectively.
set INTEL_POWER_PLAN_2_PG_GRID_CONFIG(mesh_upf_1aosv) {
  m2 {
    pullback 0.08
    power_va_primary {
      pitch 1.08
      offset,width {
        0.000  0.044
      }
    }
    ground {
      pitch 1.08
      offset,width {
        0.540  0.044
      }
    }
  }
  m3 {
    pullback 0.08
    ground {
      pitch 1.08
      offset,width {
        0.00 0.044
      }
    }
    power_va_primary {
      pitch 1.08
      offset,width {
        0.54  0.044
      }
    }
  }
  m4 {
    pullback 0.08
    ground {
      pitch 1.08
      offset,width {
        0.00  0.044
      }
    }
    power_va_primary {
      pitch 1.08
      offset,width {
        0.54  0.044
      }
    }
  }
  m5 {
    pullback 0.08
    ground {
      pitch 1.08
      offset,width {
        0.00  0.044
      }
    }
    power_va_primary {
      pitch 1.08
      offset,width {
        0.54  0.044
      }
    }
  }
  m6 {
    pullback 0.08
    ground {
      pitch 2.16
      offset,width {
        0.000  0.160
      }
    }
    power_va_primary {
      pitch 4.32
      offset,width {
        1.08  0.160
      }
    }
    power_va_aon {
      pitch 4.32
      offset,width {
        3.24  0.160
      }
    }
  }
 m7 {
    pullback 0
    ground {
      pitch 4.32
      offset,width {
        0.00  0.180
      }
    }
    power_all_aon {
      pitch 4.32
      offset,width {
        2.16  0.180
      }
    }
  }
  m8 {
    pullback 0
    ground {
      pitch 4.32
      offset,width {
        0.00  0.180
      }
    }
    power_all_aon {
      pitch 4.32
      offset,width {
        2.16  0.180
      }
    }
  }
}


# Order of the 2 always-on power nets is based on $INTEL_UPF_POWER_NETS var, i.e. {aon,1 aon,2}.
# TODO: Check if even necessary for m4 & m5 power_va_aon, since they compromise m4 & m5 power_va_primary, 1 instead 3 per 3.192 & 5.04 pitches respectively.
set INTEL_POWER_PLAN_2_PG_GRID_CONFIG(mesh_upf_2aosv) {
   m2 {
    pullback 0.08
    power_va_primary {
      pitch 1.08
      offset,width {
        0.000  0.044
      }
    }
    ground {
      pitch 1.08
      offset,width {
        0.540  0.044
      }
    }
  }
  m3 {
    pullback 0.08
    ground {
      pitch 1.08
      offset,width {
        0.00 0.044
      }
    }
    power_va_primary {
      pitch 1.08
      offset,width {
        0.54  0.044

      }
    }
  }
  m4 {
    pullback 0.08
    ground {
      pitch 1.08
      offset,width {
        0.00  0.044
      }
    }
    power_va_primary {
      pitch 1.08
      offset,width {
        0.54  0.044
      }
    }
  }
  m5 {
    pullback 0.08
    ground {
      pitch 1.08
      offset,width {
        0.00  0.044
      }
    }
    power_va_primary {
      pitch 1.08
      offset,width {
        0.54  0.044
      }
    }
  }
  m6 {
    pullback 0.08
    ground {
      pitch 2.16
      offset,width {
        0.000  0.160
      }
    }
    power_va_primary {
      pitch 4.32 
      offset,width {
        1.08  0.160
      }
    }
    power_va_aon,1 {
      pitch 4.32
      offset,width {
        3.24  0.160
      }
    }
    power_va_aon,2 {
      pitch 4.32
      offset,width {
        3.24  0.160
      }
    }
  }
 m7 {
    pullback 0
    ground {
      pitch 4.32
      offset,width {
        0.00  0.180
      }
    }
    power_all_aon,1 {
      pitch 4.32
      offset,width {
        2.16  0.180
      }
    }
    power_all_aon,2 {

      pitch 4.32
      offset,width {
        2.16  0.180
      }
    }
  }
  m8 {
    pullback 0
    ground {
      pitch 4.32
      offset,width {
        0.00  0.180
      }
    }
    power_all_aon,1 {
      pitch 4.32
      offset,width {
        2.16  0.180
      }
    }
    power_all_aon,2 {
      pitch 4.32
      offset,width {
        2.16  0.180
      }
    }
  }
}

set upf_available [string is space [get_flow_config -quiet init_power_intent_files 1801]]
if {!($upf_available)} {
  if { $INTEL_POWER_PLAN == {mesh_upf_1aosv} } {
    set INTEL_PG_GRID_CONFIG $INTEL_POWER_PLAN_2_PG_GRID_CONFIG($INTEL_POWER_PLAN)
  } elseif { $INTEL_POWER_PLAN == {mesh_upf_2aosv} } {
    set INTEL_PG_GRID_CONFIG $INTEL_POWER_PLAN_2_PG_GRID_CONFIG($INTEL_POWER_PLAN)
  } else {
    P_msg_error "Unsupported UPF power plan '$INTEL_POWER_PLAN' defined by 'INTEL_POWER_PLAN' var!  Expect 1 of 'mesh_upf_1aosv mesh_upf_2aosv'!"
  }
} else {
  set INTEL_PG_GRID_CONFIG $INTEL_POWER_PLAN_2_PG_GRID_CONFIG(mesh_nonupf)
}
# EOF

