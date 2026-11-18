all:
	verilator --cc --Wno-fatal --trace --build -I.. -prof-cfuncs -CFLAGS -DVL_DEBUG --binary $(file_main)

iverilog:
	iverilog -Wall -g2023 -I .. -c files.txt

clean:
	rm -rf obj_dir
	rm *.out

