#!/bin/sh
# 
# PlanAhead(TM)
# runme.sh: PlanAhead-generated Script for launching ISim application
# Copyright 1986-1999, 2001-2012 Xilinx, Inc. All Rights Reserved.
# 
if [ -z "$PATH" ]; then
  PATH=%XILINX%\lib\%PLATFORM%;%XILINX%\bin\%PLATFORM%:C:/Xilinx/14.6/ISE_DS/EDK/bin/nt;C:/Xilinx/14.6/ISE_DS/EDK/lib/nt;C:/Xilinx/14.6/ISE_DS/ISE/bin/nt;C:/Xilinx/14.6/ISE_DS/ISE/lib/nt;C:/Xilinx/14.6/ISE_DS/common/bin/nt;C:/Xilinx/14.6/ISE_DS/common/lib/nt
else
  PATH=%XILINX%\lib\%PLATFORM%;%XILINX%\bin\%PLATFORM%:C:/Xilinx/14.6/ISE_DS/EDK/bin/nt;C:/Xilinx/14.6/ISE_DS/EDK/lib/nt;C:/Xilinx/14.6/ISE_DS/ISE/bin/nt;C:/Xilinx/14.6/ISE_DS/ISE/lib/nt;C:/Xilinx/14.6/ISE_DS/common/bin/nt;C:/Xilinx/14.6/ISE_DS/common/lib/nt:$PATH
fi
export PATH

if [ -z "$LD_LIBRARY_PATH" ]; then
  LD_LIBRARY_PATH=:
else
  LD_LIBRARY_PATH=::$LD_LIBRARY_PATH
fi
export LD_LIBRARY_PATH

#
# Setup env for Xilinx simulation libraries
#
XILINX_PLANAHEAD=C:/Xilinx/14.6/ISE_DS/PlanAhead
export XILINX_PLANAHEAD
ExecStep()
{
   "$@"
   RETVAL=$?
   if [ $RETVAL -ne 0 ]
   then
       exit $RETVAL
   fi
}


ExecStep fuse -intstyle pa -incremental -L work -L secureip -o watchdog_tb.exe --prj C:/Users/ulab/Desktop/project_6/project_6.sim/sim_1/behav/watchdog_tb.prj -top work.watchdog_tb
