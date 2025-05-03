# specify special QRC map file to properly handle backside metal
set file $env(INTEL_PDK)/extraction/qrc/asic/$env(LAYERSTACK)/asic.qrc.map
if {[file exists $file] && [file readable $file]} { 
  set_db extract_rc_lef_tech_file_map $file
} else { 
  puts "ERROR: The QRC map file: $file was not found or is not readable" 
  error
} 

