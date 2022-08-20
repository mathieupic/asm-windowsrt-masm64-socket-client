@echo off

set appname=socket

if exist %1.obj del %appname%.obj
if exist %1.exe del %appname%.exe

ml64.exe /c /nologo %appname%.asm
link.exe /SUBSYSTEM:CONSOLE /ENTRY:entry_point %appname%.obj

dir %appname%.*

pause