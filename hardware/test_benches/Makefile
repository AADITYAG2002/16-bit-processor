all:
	verilator --cc --Wno-fatal --trace --build -I.. -prof-cfuncs -CFLAGS -DVL_DEBUG --binary $(file_main)

clean:
	rm -rf .obj_dir
	rm *.vcd
