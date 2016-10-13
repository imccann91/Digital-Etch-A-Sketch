@echo off


rem  PlanAhead(TM)
rem  runme.bat: a PlanAhead-generated ISim simulation Script
rem  Copyright 1986-1999, 2001-2012 Xilinx, Inc. All Rights Reserved.


set PATH=%XILINX%\lib\%PLATFORM%;%XILINX%\bin\%PLATFORM%;C:/Xilinx/14.6/ISE_DS/EDK/bin/nt;C:/Xilinx/14.6/ISE_DS/EDK/lib/nt;C:/Xilinx/14.6/ISE_DS/ISE/bin/nt;C:/Xilinx/14.6/ISE_DS/ISE/lib/nt;C:/Xilinx/14.6/ISE_DS/common/bin/nt;C:/Xilinx/14.6/ISE_DS/common/lib/nt;C:/Xilinx/14.6/ISE_DS/PlanAhead/bin;%PATH%

set XILINX_PLANAHEAD=C:/Xilinx/14.6/ISE_DS/PlanAhead

fuse -intstyle pa -incremental -L work -L secureip -o watchdog_tb.exe --prj C:/Users/ulab/Desktop/project_6/project_6.sim/sim_1/behav/watchdog_tb.prj -top work.watchdog_tb
if errorlevel 1 (
   cmd /c exit /b %errorlevel%
)
