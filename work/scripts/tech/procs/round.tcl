## Script to dump histogram in tempus
proc round {number {digits 0}} { 
 if { $digits} { return [expr {round(pow(10,$digits)*$number)/pow(10,$digits)}] } 
 else { return [ int [expr {round(pow(10,$digits)*$number)/pow(10,$digits)}]] }
} 

