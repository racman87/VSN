



# !/usr/bin/tclsh

# Main proc at the end #

#------------------------------------------------------------------------------
proc compile_duv { } {
  global Path_DUV
  puts "\nVHDL DUV compilation :"

  vlog $Path_DUV/avalon_generator.sv
}

#------------------------------------------------------------------------------
proc compile_tb { } {
  global Path_TB
  global Path_DUV
  puts "\nVHDL TB compilation :"

  vlog $Path_TB/avalon_assertions.sv
  vlog $Path_TB/avalon_assertions_wrapper.sv
}

#------------------------------------------------------------------------------
proc sim_start {AVALONMODE TESTCASE} {

  vsim -assertdebug -novopt -GAVALONMODE=$AVALONMODE -GTESTCASE=$TESTCASE work.avalon_assertions_wrapper
  view assertions
  atv log -enable /avalon_assertions_wrapper/duv/binded
  add wave -r *

  switch $AVALONMODE {
    0 {
        # Add corresponding assertions
        add wave /avalon_assertions_wrapper/duv/binded/assert_waitrequest/assert_waitreq1
        add wave /avalon_assertions_wrapper/duv/binded/assert_waitrequest/assert_stable
        add wave /avalon_assertions_wrapper/duv/binded/assert_waitrequest/assert_stable_write
        add wave /avalon_assertions_wrapper/duv/binded/assert_waitrequest/assert_read_stable
        add wave /avalon_assertions_wrapper/duv/binded/assert_waitrequest/assert_read
        add wave /avalon_assertions_wrapper/duv/binded/assert_waitrequest/assert_readdatavalid
    }
    1 {
        # Add corresponding assertions
        add wave /avalon_assertions_wrapper/duv/binded/assert_fixed/assert_fixed1
        add wave /avalon_assertions_wrapper/duv/binded/assert_fixed/assert_stable_read
        add wave /avalon_assertions_wrapper/duv/binded/assert_fixed/assert_stable_write
    }
    2 {
        # Add corresponding assertions
        add wave /avalon_assertions_wrapper/duv/binded/assert_pipeline_variable/assert_stable
        add wave /avalon_assertions_wrapper/duv/binded/assert_pipeline_variable/assert_counter
        add wave /avalon_assertions_wrapper/duv/binded/assert_pipeline_variable/assert_readdatavalid
    }
    3 {
        # Add corresponding assertions
        add wave /avalon_assertions_wrapper/duv/binded/assert_pipeline_fixed/assert_stable
        add wave /avalon_assertions_wrapper/duv/binded/assert_pipeline_fixed/assert_readdatavalid
    }
    4 {
        # Add corresponding assertions
        add wave /avalon_assertions_wrapper/duv/binded/assert_burst/assert_stable_waitreq
        add wave /avalon_assertions_wrapper/duv/binded/assert_burst/assert_readaddr_stable
        add wave /avalon_assertions_wrapper/duv/binded/assert_burst/assert_readdatavalid
    }
  }
  run -all
}

#------------------------------------------------------------------------------
proc do_all {AVALONMODE TESTCASE} {
  compile_duv
  compile_tb
  sim_start $AVALONMODE $TESTCASE
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
  if {$argc>1} {
    do_all $1 $2
  } else {
    do_all $1 0
  }
} else {
  do_all 0 0
}
