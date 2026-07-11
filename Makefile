#   make MOD=pc        			  compile rtl/ + that tb, run; a test FAIL exits nonzero
#   make wave MOD=pc  	    	  same, then open the waveform in surfer (opens even on FAIL)
#   make clean                    delete build artifacts (build/, *.vcd)

RTL := $(wildcard rtl/*.sv)
TB  := tb/$(MOD)_tb.sv
SIM := build/sim
WAVE_STATE := tb/$(MOD).ron
FORMAL := formal/$(MOD).sby

run:
	@test -n "$(MOD)" || { echo "usage: make MOD=<module>  (e.g. MOD=uart_rx)"; exit 1; }
	@mkdir -p build
	iverilog -g2012 -s $(MOD)_tb -o $(SIM) $(RTL) $(TB)
	vvp $(SIM)

wave:
	@test -n "$(MOD)" || { echo "usage: make wave MOD=<module>"; exit 1; }
	@mkdir -p build
	iverilog -g2012 -s $(MOD)_tb -o $(SIM) $(RTL) $(TB)
	-vvp $(SIM)
	surfer $$(ls *.vcd 2>/dev/null | head -1) $$(test -f $(WAVE_STATE) && echo "-s $(WAVE_STATE)") &

clean:
	rm -rf build *.vcd sim_build results.xml

.DEFAULT_GOAL := run