ca65 $PSScriptRoot/hello_world.s -o $PSScriptRoot/hello_world.o
ld65 $PSScriptRoot/hello_world.o -C $PSScriptRoot/linker.cfg -o $PSScriptRoot/hello_world.bin -m $PSScriptRoot/hello_world.map
