proc P_outputs_oas {step} {
global vars
write_oasis $vars(INTEL_OUTPUTS_PATH)/$vars(INTEL_DESIGN_NAME).${step}.oas   \
-map_file $vars(INTEL_OAS_LAYER_MAP)   \
-attach_instance_name 112   \
-die_area_as_boundary   \
-units 2000   \
-merge $vars(INTEL_OAS_FILES)   \
-structure_name $vars(INTEL_DESIGN_NAME) 
}
