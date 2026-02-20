ca65 ./examples/hello_world/hello_world.s -o ./examples/hello_world/hello_world.o
ld65 ./examples/hello_world/hello_world.o -C ./examples/hello_world/linker.cfg -o ./examples/hello_world/hello_world.bin -m ./examples/hello_world/hello_world.map
lune run examples/hello_world