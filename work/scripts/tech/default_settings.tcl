#######################################################################
# layers setting
#######################################################################
#PG pinlayers and port layers used by create_lef and interface_metals steps
set vars(INTEL_TOP_PG_PIN_LAYER) "m7 m8"
set vars(INTEL_PORT_LAYERS) "m6 m7"

#######################################################################
#NDR default setting
#######################################################################
#set vars(INTEL_ENABLE_DEFAULT_CLK_SHIELD)   0
#set vars(INTEL_ENABLE_DEFAULT_CLK_NOSHIELD)    0
#set vars(INTEL_ENABLE_NDR_CLK_SHIELD)  0
#set vars(INTEL_ENABLE_NDR_CLK_NOSHIELD)  0


#######################################################################
#Nets setting
#######################################################################
# Define power/ground nets
set vars(INTEL_GROUND_NET) [get_flow_config init_ground_nets]
set vars(INTEL_POWER_NET)  [get_flow_config init_power_nets]
set vars(INTEL_POWER_PIN_NAMES)  "vcc"
set vars(INTEL_GROUND_PIN_NAMES)  "vss vssx"



set vars(hard_macro_refs) ""

#######################################################################
#Customizable PG pullback values for macros & voltage area
#######################################################################
#HSD 16015352710
set vars(pg_pullback_va) {"m1 0.040" "m2 0.040" "m3 0.040" "m4 0.040" "m5 0.040" "m6 0.040" "m7 0.36" "m8 0.36"}
#set vars(pg_pullback_va) {"m1 0.040" "m2 0.040" "m3 0.040" "m4 0.040" "m5 0.040" "m6 0.040" "m7 0.48" "m8 0.36"}
set vars(pg_pullback_macro) {"m1 0.160" "m2 0.160" "m3 0.160" "m4 0.160" "m5 0.160" "m6 0.160" "m7 0.48" "m8 0.36"}

#######################################################################
#INFRASTRUCTURE SETTINGS
#######################################################################
set vars(INTEL_REPORTS_PATH)            "$env(WORK_DIR)/reports"
set vars(INTEL_OUTPUTS_PATH)            "$env(WORK_DIR)/outputs"

#######################################################################
#DESIGN SETTINGS
#######################################################################
set vars(INTEL_DESIGN_NAME)		""
set vars(INTEL_DESIGN_NAME) [get_flow_config design_name]
set vars(INTEL_CURRENT_STEP) [get_db flow_report_name]
set INTEL_POWER_PLAN mesh_upf_1aosv

set vars(INTEL_OAS_FILES) ""
set vars(INTEL_OAS_FILES) [get_flow_config cell_layout_files]

