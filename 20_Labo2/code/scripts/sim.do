
# !/usr/bin/tclsh

# Main proc at the end #

#------------------------------------------------------------------------------
proc compile_duv { } {
  global Path_DUV
  puts "\nVHDL DUV compilation :"

  vcom $Path_DUV/alu.vhd
}

#------------------------------------------------------------------------------
proc compile_tb { } {
  global Path_TB
  global Path_DUV
  puts "\nVHDL TB compilation :"

  vcom $Path_TB/alu_tb.vhd
}

#------------------------------------------------------------------------------
proc sim_start {TESTCASE SIZE ERRNO} {

  vsim -t 1ns -novopt -GSIZE=$SIZE -GERRNO=$ERRNO -GTESTCASE=$TESTCASE -novopt work.alu_tb
#  do wave.do
  #add wave -r *
  add wave -expand -group Stimuli *_sti
  add wave -expand -group Observ *_obs
  add wave -expand -group Error *_s
  wave refresh
  run -all
}

#------------------------------------------------------------------------------
proc do_all {TESTCASE SIZE ERRNO} {
  compile_duv
  compile_tb
  sim_start $TESTCASE $SIZE $ERRNO
}

## MAIN #######################################################################

# Compile folder ----------------------------------------------------
if {[file exists work] == 0} {
  vlib work
}

puts -nonewline "  Path_VHDL => "
set Path_DUV     "../src"
set Path_TB       "../src_tb"

global Path_DUV
global Path_TB

# start of sequence -------------------------------------------------


if {$argc>0} {
  if {[string compare $1 "all"] == 0} {
    do_all 0 $2 $3
  } elseif {[string compare $1 "comp_duv"] == 0} {
    compile_duv
  } elseif {[string compare $1 "comp_tb"] == 0} {
    compile_tb
  } elseif {[string compare $1 "sim"] == 0} {
    sim_start 0 $2
  }

} else {
  do_all 0 8 0
  sim_start 0 8 1
  sim_start 0 8 2
  sim_start 0 8 3
  sim_start 0 8 4
  sim_start 0 8 5
  sim_start 0 8 6
  sim_start 0 8 7
  sim_start 0 8 8
  sim_start 0 8 9
  sim_start 0 8 10
  sim_start 0 8 11
  sim_start 0 8 12
  sim_start 0 8 13
  sim_start 0 8 14
  sim_start 0 8 15
  sim_start 0 8 16
  sim_start 0 8 17
  sim_start 0 8 18
  sim_start 0 8 19
  sim_start 0 8 20
  sim_start 0 8 21
  sim_start 0 8 22
  sim_start 0 8 23
  sim_start 0 8 24
}
