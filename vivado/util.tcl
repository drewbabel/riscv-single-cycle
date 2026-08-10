# Util repro

set root    [file normalize [file join [file dirname [info script]] ..]]
set mods    $argv
set part    xc7a35tcpg236-1

proc count_cells {pattern} {
  if {[catch {llength [get_cells -hier -quiet -filter "REF_NAME =~ $pattern"]} n]} { return -1 }
  return $n
}

set pkgs {}
set rest {}
foreach f [lsort [glob [file join $root rtl *.sv]]] {
  if {[string match *_pkg [file rootname [file tail $f]]]} { lappend pkgs $f } else { lappend rest $f }
}

foreach mod $mods {
  set outdir [file join $root vivado_out $mod]
  file mkdir $outdir

  read_verilog -sv $pkgs
  read_verilog -sv $rest

  synth_design -top $mod -part $part -mode out_of_context -flatten_hierarchy full

  report_utilization -file [file join $outdir utilization.rpt]

  set fh [open [file join $outdir summary.txt] w]
  puts $fh "module $mod"
  puts $fh [format "luts %d"      [count_cells "LUT*"]]
  puts $fh [format "flipflops %d" [count_cells "FD*"]]
  close $fh
  puts "RESULT $mod luts [count_cells LUT*] flipflops [count_cells FD*]"

  close_design
}

puts "RESULT all done"
