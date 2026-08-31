design:
	yosys \
		-p "read_verilog -sv $(file_main).sv" \
		-p "hierarchy -check" \
		-p "proc; opt;" \
		-p "show -prefix $(file_main) -colors 1 -width"\
		-p "write_json $(file_main).json"
	netlistsvg -o $(file_main).svg $(file_main).json

.PHONY: clean
clean:
	rm *.dot *.pid *.json *.svg
