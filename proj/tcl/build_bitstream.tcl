open_project ./pynq_z2_rtl/pynq_z2_rtl.xpr

update_compile_order -fileset sources_1

reset_run synth_1
reset_run impl_1

# Place & route only -- stop short of bitstream generation.
launch_runs impl_1 -to_step route_design -jobs 32
wait_on_run impl_1

if {[get_property PROGRESS [get_runs impl_1]] ne "100%"} {
    puts "ERROR: impl_1 did not complete (status: [get_property STATUS [get_runs impl_1]])."
    exit 1
}

# Load the routed design and enforce timing closure before emitting a bitstream.
open_run impl_1
set wns [get_property SLACK [get_timing_paths -setup -nworst 1 -max_paths 1]]
set whs [get_property SLACK [get_timing_paths -hold  -nworst 1 -max_paths 1]]
puts "==> Timing closure: WNS = $wns ns, WHS = $whs ns"

if {$wns < 0 || $whs < 0} {
    puts "ERROR: timing NOT met (WNS = $wns ns, WHS = $whs ns) -- no bitstream generated."
    exit 1
}

# Timing is clean -- safe to emit the bitstream.
write_bitstream -force ./pynq_z2_rtl.bit
puts "==> Bitstream written: ./pynq_z2_rtl.bit"
