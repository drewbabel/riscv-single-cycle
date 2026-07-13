// Co-sim commit monitor
// tests/cosim.py diffs COMMIT lines against Spike

module cosim ();

  int checks = 0;
  int errors = 0;

  localparam int Xlen  = 32;
  localparam int Depth = 64;

  logic            clk = 1'b0;
  logic            rst_n;
  logic [Xlen-1:0] pc;
  logic [Xlen-1:0] alu_result;
  logic [Xlen-1:0] write_data;
  logic            mem_write;

  string hexfile;
  int    max_commits;

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

  task automatic do_reset();
    rst_n = 0;
    repeat (2) @(posedge clk);
    rst_n = 1;
  endtask  // Automatic

  // one line per retired instruction
  task automatic emit_commit();
    logic [Xlen-1:0] instr;
    logic [     4:0] rd;
    logic            rw;
    instr = dut.instr;
    rd    = instr[11:7];
    rw    = dut.riscv_single_inst.reg_write;
    // pc rd rd_val mem_write mem_addr mem_val
    $display("COMMIT %08x %0d %08x %0d %08x %08x", pc, (rw && rd != 0) ? rd : 0,
             dut.riscv_single_inst.datapath_inst.result, mem_write, alu_result, write_data);
    checks++;
  endtask  // Automatic

  task automatic verdict();
    if (errors == 0) $display("MONITOR: %0d commits", checks);
    else $fatal(1, "MONITOR FAIL: %0d errors", errors);
    $finish;
  endtask  // Automatic

  initial begin
    logic [Xlen-1:0] pc_before;
    logic            parked;

    if (!$value$plusargs("hex=%s", hexfile)) $fatal(1, "cosim needs +hex");
    if (!$value$plusargs("n=%d", max_commits)) max_commits = 1000;

    $readmemh(hexfile, dut.imem_inst.mem);
    do_reset();

    // run until the sentinel self-loops
    parked = 0;
    for (int i = 0; i < max_commits && !parked; i++) begin
      #1;
      pc_before = pc;
      emit_commit();
      @(posedge clk);
      #1;
      if (pc === pc_before) parked = 1;
    end

    verdict();
  end

endmodule
