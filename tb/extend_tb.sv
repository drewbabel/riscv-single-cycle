module extend_tb;

  int checks = 0;
  int errors = 0;

  localparam int Xlen = 32;

  logic [31:0]     instr;
  logic [2:0]      imm_src;
  logic [Xlen-1:0] imm_ext;

  extend #(.XLEN(Xlen)) dut (
      .instr  (instr),
      .imm_src(imm_src),
      .imm_ext(imm_ext)
  );

  task automatic check(input string name, input logic [Xlen-1:0] got, input logic [Xlen-1:0] exp);
    checks++;
    if (got !== exp) begin
      $error("%s: got %h, exp %h", name, got, exp);
      errors++;
    end
  endtask  // Automatic

  task automatic do_verdict();
    if (errors == 0) begin
      $display("PASS: %0d checks, %0d mismatches", checks, errors);
    end else begin
      $fatal(1, "FAIL: %0d mismatches, %0d checks", errors, checks);
    end
    $finish;
  endtask  // Automatic

  initial begin
    $dumpfile("extend_tb.vcd");
    $dumpvars(0, extend_tb);

    // Golden vectors assembled with riscv64-elf-gcc (rv32i)
    instr = 32'hffc00093; imm_src = 3'd0; #1; check("I neg addi -4", imm_ext, 32'hfffffffc);
    instr = 32'h00500113; imm_src = 3'd0; #1; check("I pos addi 5",  imm_ext, 32'h00000005);
    instr = 32'hfe322c23; imm_src = 3'd1; #1; check("S neg sw -8",   imm_ext, 32'hfffffff8);
    instr = 32'hfe6288e3; imm_src = 3'd2; #1; check("B neg beq -16", imm_ext, 32'hfffffff0);
    instr = 32'h123453b7; imm_src = 3'd3; #1; check("U lui 0x12345", imm_ext, 32'h12345000);
    instr = 32'h0100046f; imm_src = 3'd4; #1; check("J pos jal +16", imm_ext, 32'h00000010);
    instr = 32'hff9ff4ef; imm_src = 3'd4; #1; check("J neg jal -8",  imm_ext, 32'hfffffff8);

    do_verdict();
  end

endmodule
