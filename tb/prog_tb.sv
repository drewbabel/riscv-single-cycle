module prog_tb ();

  localparam int Xlen = 32;
  localparam int Depth = 64;
  localparam int MaxCycles = 20000;

  logic            clk = 1'b0;
  logic            rst_n;
  logic [Xlen-1:0] pc;
  logic [Xlen-1:0] alu_result;
  logic [Xlen-1:0] write_data;
  logic            mem_write;

  string hexfile;

  always #5 clk = ~clk;

  top #(
      .XLEN (Xlen),
      .DEPTH(Depth)
  ) dut (
      .clk       (clk),
      .rst_n     (rst_n),
      .pc        (pc),
      .alu_result(alu_result),
      .write_data(write_data),
      .mem_write (mem_write)
  );

  wire [Xlen-1:0] x28 = dut.riscv_single_inst.datapath_inst.regfile_inst.regfile_mem[28];

  task automatic do_reset();
    rst_n = 0;
    repeat (2) @(posedge clk);
    rst_n = 1;
  endtask  // Automatic

  initial begin
    if (!$value$plusargs("HEX=%s", hexfile)) $fatal(1, "usage: +HEX=<file>");
    $readmemh(hexfile, dut.imem_inst.mem);
    do_reset();
    repeat (MaxCycles) begin
      @(posedge clk);
      if (x28 == 32'd1) begin
        $display("PASS: %s", hexfile);
        $finish;
      end
      if (x28 == 32'hdead) $fatal(1, "FAIL: %s left x28=dead", hexfile);
    end
    $fatal(1, "FAIL: %s timed out, x28=%08h", hexfile, x28);
  end

endmodule
