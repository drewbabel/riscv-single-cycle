#   make MOD=pc                  compile rtl/ + that tb, run; a test FAIL exits nonzero
#   make wave MOD=alu            same, then open the waveform in surfer (opens even on FAIL)
#   make view MOD=alu            open testbench waveform in surfer (no rerun); error if .vcd missing
#   make view-formal MOD=alu     open formal waveform; error if .vcd missing
#   make formal MOD=alu          run every SymbiYosys task in formal/$(MOD).sby; a FAIL exits nonzero
#   make clean                   delete build artifacts (build/, *.vcd)

# alu_pkg.sv must compile before any module that imports it
RTL := $(wildcard rtl/alu_pkg.sv) $(filter-out rtl/alu_pkg.sv,$(wildcard rtl/*.sv))
TB  := tb/$(MOD)_tb.sv
SIM := build/sim
WAVE_STATE := tb/$(MOD).ron
FORMAL := formal/$(MOD).sby

run:
	@test -n "$(MOD)" || { echo "usage: make MOD=<module>  (e.g. MOD=alu)"; exit 1; }
	@mkdir -p build
	iverilog -g2012 -s $(MOD)_tb -o $(SIM) $(RTL) $(TB)
	vvp $(SIM)

wave:
	@test -n "$(MOD)" || { echo "usage: make wave MOD=<module>"; exit 1; }
	@mkdir -p build
	iverilog -g2012 -s $(MOD)_tb -o $(SIM) $(RTL) $(TB)
	-vvp $(SIM)
	surfer $$(ls *.vcd 2>/dev/null | head -1) $$(test -f $(WAVE_STATE) && echo "-s $(WAVE_STATE)") &

formal:
	@test -n "$(MOD)" || { echo "usage: make formal MOD=<module>  (e.g. MOD=alu)"; exit 1; }
	@mkdir -p build
	sv2v -E Assert $(RTL) formal/$(MOD)_formal.sv > build/$(MOD)_formal.v
	sby -f $(FORMAL)

view:
	@test -n "$(MOD)" || { echo "usage: make view MOD=<module>"; exit 1; }
	@test -f "tb/$(MOD).ron" || { echo "Error: tb/$(MOD).ron not found"; exit 1; }
	@test -f "$$(ls *.vcd 2>/dev/null | head -1)" || { echo "Error: no .vcd found"; exit 1; }
	surfer $$(ls *.vcd 2>/dev/null | head -1) -s tb/$(MOD).ron &

view-formal:
	@test -n "$(MOD)" || { echo "usage: make view-formal MOD=<module>  (e.g. MOD=alu)"; exit 1; }
	@test -f "formal/$(MOD).ron" || { echo "Error: formal/$(MOD).ron not found"; exit 1; }
	@test -f "$$(find formal/$(MOD) -name '*.vcd' 2>/dev/null | head -1)" || { echo "Error: no .vcd found in formal/$(MOD)/"; exit 1; }
	surfer $$(find formal/$(MOD) -name '*.vcd' 2>/dev/null | head -1) -s formal/$(MOD).ron &

clean:
	rm -rf build *.vcd sim_build results.xml

.DEFAULT_GOAL := run
.PHONY: run wave formal view view-formal clean
