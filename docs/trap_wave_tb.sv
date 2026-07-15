`timescale 1ns / 1ps
// throwaway trap waveform tb, generates trap_wave.csv
//   iverilog -g2012 -s trap_wave_tb -o w.vvp rtl/alu_pkg.sv rtl/csr_pkg.sv $(ls rtl/*.sv | grep -v _pkg) docs/trap_wave_tb.sv && vvp w.vvp
//   python3 docs/trap_waveform.py
module trap_wave_tb;
  localparam int Xlen  = 32;
  localparam int Depth = 64;

  logic            clk = 1'b0;
  logic            rst_n;
  logic [Xlen-1:0] pc;
  logic [Xlen-1:0] alu_result;
  logic [Xlen-1:0] write_data;
  logic            mem_write;

  always #5 clk = ~clk;

  top #(.XLEN(Xlen), .DEPTH(Depth)) dut (
      .clk(clk), .rst_n(rst_n), .pc(pc),
      .alu_result(alu_result), .write_data(write_data), .mem_write(mem_write)
  );

  task automatic do_reset();
    rst_n = 0;
    repeat (2) @(posedge clk);
    rst_n = 1;
  endtask

  integer f;
  initial begin
    f = $fopen("trap_wave.csv", "w");
    $fwrite(f, "pc,timer_irq,trap_taken,mcause,mepc\n");
    $readmemh("tests/timer.hex", dut.imem_inst.mem);
    do_reset();
    #1;
    repeat (44) begin
      $fwrite(f, "%0d,%0d,%0d,%0d,%0d\n",
              pc, dut.timer_irq, dut.riscv_single_inst.trap_taken,
              dut.riscv_single_inst.csr_inst.mcause,
              dut.riscv_single_inst.csr_inst.mepc);
      @(posedge clk);
      #1;
    end
    $fclose(f);
    $finish;
  end
endmodule
