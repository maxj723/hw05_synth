
proc P_read_lib_maxcap {args} {
  parse_proc_arguments -args $args inputs
  set lib_list $inputs(-lib)
  set out_file $inputs(-out_file)

	global ptta_maxcap
	global ptta_maxcap_fixed
	global ptta_maxcap_checker
	global ptta_maxcap_indices
	global cellcount
	global pincount
	global verbose 
	global clocksHash
	set cellcount 0
	set pincount 0
	set isgz 0
  
  set outFile [open $out_file "w"]
  set all_libs [glob -nocomplain $lib_list]

  if { [llength $all_libs ] == 0 } {
    puts "ERROR: No libs found. Please check lib path"
  }

  foreach libname $all_libs {
    if {[file exists $libname]} {
      puts "Processing    $libname"
  		set s1 ".lib.gz"
  		set newlibname [string trimright $libname $s1]
  		set libname_gz "$newlibname.lib.gz"
  		if {[file exists $libname_gz]} {
  			#puts "Found gz version of libfile ($libname_gz)"
        while {[file type $libname_gz] eq "link"} {
          set newfile [file readlink $libname_gz]
            if {[string index $newfile 0] ne "/"} {
              set newfile [file dirname $libname_gz]/$newfile
            }
            set libname_gz $newfile
        }
  			file copy $libname_gz .
  			set currLibnamegz "./[file tail $libname_gz]"
  			#puts "Bunzipping $currLibnamegz"
  			exec gunzip $currLibnamegz
  			regsub {.gz} $currLibnamegz "" currLibname
  			set libname $currLibname
  			#puts "Pointing to bunzipped version: $currLibname"
  			set isgz 1
      }
  	
  	set libfile [open $libname]
  	#puts "libfile is $libname"
  	while {[gets $libfile line] > -1} {
  		if { [regexp {^\s*cell\s*\(\"([^\"]+)\"\)} $line skip cell] ||[regexp {^\s*cell*\((.*)\)} $line skip cell] } {
  		  incr cellcount
  		} elseif { [regexp {^\s*pin\s*\(\"([^\"]+)\"\)} $line skip pin] || [regexp {^\s*pin*\((.*)\)} $line skip pin] } {
  		  incr pincount
      } elseif { [regexp {^\s*max_capacitance\s*} $line]} {
        puts "$line"
  		} elseif { [regexp {^\s*max_cap\s*\(} $line] } {
  			while { [gets $libfile line] > -1} {
  				if { [regexp {^\s*index_1\s*\(\"([^\"]+)\"\)} $line skip indices] } { 
  				  ##puts "$cell \t $pin"
  				  #set line1 [string trimleft $line]	
  				  #puts "$line"
  				  # set indexList [split [join [split $indices " ," ] ] ]
  				  set indexList [split $indices , ] 
  				  #scale frequency from 1/1ps to Hz
  				  set freqList [list]
  				  foreach val $indexList {
  				    set fr [format {%g} [ expr ${val} * 1e12 ] ]
  				    lappend freqList $fr
  				  }
  
  				  ;# puts $indexList
  				} elseif {[regexp {^\s*values\s*\(\"([^\"]+)\"} $line skip values]} {
  				   #set line1 [string trimleft $line]
  				   #puts "$line"
  				   set valueList [split $values "," ] 
  				   #chnge unit to pf
  				   set capList [list]
  				   foreach val $valueList {
  				     set cap [format {%g} [ expr ${val} / 1000 ] ]
  				     lappend capList $cap
  				   }
             puts $outFile "set_max_cap_per_freq -cap {$capList} -freq {$freqList} -pins {$cell $pin} -force "
  				   break
  				} 
  			}
  			for {set i 0} {$i < [llength $indices]} {incr i} {
  			  set index [lindex $indices $i] 
  			  set value [lindex $valueList $i]
  			  set ptta_maxcap($cell,$pin,$index) $value
  			  set ptta_maxcap_indices($index) 1
  			  set ptta_maxcap_checker($cell,$pin) 1
  			}
  		} 
  	}
  	close $libfile	
  	if {$isgz} {
  		if {[file exists $libname]} {
  			file delete $libname
  		}
  	}
  
    } else {
      puts "ERROR: $libname not found. Please provide correct absolute path"
    }
  }
  close $outFile

  if {[file exists $out_file]} {
    source $out_file
  } else {
    puts "ERROR: $out_file is not generated."
  }
}

define_proc_arguments P_read_lib_maxcap \
-info "This procedure creates tcl with freq. based cap tables from cmax libs. "  \
-define_args {
    {-lib    "Absolute path to cmax lib. Wild card is allowd to give multiple libs as input" "val" string required }
    {-out_file    "Output file name" "val" string required }
 } 


