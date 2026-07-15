module rvfi_wrapper (
    input clock,
    input reset,
    `RVFI_OUTPUTS
);

  // Free solver inputs
  (* keep *)`rvformal_rand_reg [31:0] instr;
  (* keep *)`rvformal_rand_reg [31:0] read_data;

  (* keep *)logic              [31:0] pc;
  (* keep *)logic              [31:0] alu_result;
  (* keep *)logic              [31:0] write_data;
  (* keep *)logic              [ 3:0] store_wstrb;
  (* keep *)logic              [31:0] store_data;
  (* keep *)logic                     mem_write;

  // Formal-only taps
  (* keep *)logic              [31:0] dbg_rs1_data;
  (* keep *)logic              [31:0] dbg_rd_wdata;
  (* keep *)logic                     dbg_reg_write;
  (* keep *)logic                     dbg_trap;
  (* keep *)logic              [31:0] dbg_csr_wdata;
  (* keep *)logic              [31:0] dbg_mscratch;
  (* keep *)logic              [31:0] dbg_mstatus;
  (* keep *)logic              [31:0] dbg_mtvec;
  (* keep *)logic              [31:0] dbg_mepc;
  (* keep *)logic              [31:0] dbg_mcause;
  (* keep *)logic              [31:0] dbg_mtval;
  (* keep *)logic              [31:0] dbg_mie;
  (* keep *)logic              [31:0] dbg_mip;
  (* keep *)logic              [31:0] dbg_mcycle;
  (* keep *)logic              [31:0] dbg_minstret;
  (* keep *)logic              [31:0] dbg_mcycleh;
  (* keep *)logic              [31:0] dbg_minstreth;

  logic              [31:0] ret_instr;
  logic              [31:0] ret_pc;
  logic              [31:0] ret_rs1_data;
  logic              [31:0] ret_rs2_data;
  logic              [31:0] ret_rd_wdata;
  logic                     ret_reg_write;
  logic              [31:0] ret_alu_result;
  logic              [31:0] ret_read_data;
  logic              [ 3:0] ret_store_wstrb;
  logic              [31:0] ret_store_data;
  logic                     ret_trap;
  logic              [31:0] ret_mscratch;
  logic              [31:0] ret_csr_wdata;
  logic              [31:0] ret_mstatus;
  logic              [31:0] ret_mtvec;
  logic              [31:0] ret_mepc;
  logic              [31:0] ret_mcause;
  logic              [31:0] ret_mtval;
  logic              [31:0] ret_mie;
  logic              [31:0] ret_mip;
  logic              [31:0] ret_mcycle;
  logic              [31:0] ret_minstret;
  logic              [31:0] ret_mcycleh;
  logic              [31:0] ret_minstreth;
  logic                     valid_q;
  logic              [63:0] order_q;
  logic              [ 3:0] rmask_c;
  logic                     rd_nonzero;

  riscv_single uut (
      .clk          (clock),
      .rst_n        (!reset),
      .instr        (instr),
      .read_data    (read_data),
      .timer_irq    (1'b0),
      .pc           (pc),
      .mem_write    (mem_write),
      .alu_result   (alu_result),
      .write_data   (write_data),
      .store_wstrb  (store_wstrb),
      .store_data   (store_data),
      .dbg_rs1_data (dbg_rs1_data),
      .dbg_rd_wdata (dbg_rd_wdata),
      .dbg_reg_write(dbg_reg_write),
      .dbg_trap     (dbg_trap),
      .dbg_csr_wdata(dbg_csr_wdata),
      .dbg_mscratch (dbg_mscratch),
      .dbg_mstatus  (dbg_mstatus),
      .dbg_mtvec    (dbg_mtvec),
      .dbg_mepc     (dbg_mepc),
      .dbg_mcause   (dbg_mcause),
      .dbg_mtval    (dbg_mtval),
      .dbg_mie      (dbg_mie),
      .dbg_mip      (dbg_mip),
      .dbg_mcycle   (dbg_mcycle),
      .dbg_minstret (dbg_minstret),
      .dbg_mcycleh  (dbg_mcycleh),
      .dbg_minstreth(dbg_minstreth)
  );

  // Retirement register
  always_ff @(posedge clock) begin
    ret_instr       <= instr;
    ret_pc          <= pc;
    ret_rs1_data    <= dbg_rs1_data;
    ret_rs2_data    <= write_data;
    ret_rd_wdata    <= dbg_rd_wdata;
    ret_reg_write   <= dbg_reg_write;
    ret_alu_result  <= alu_result;
    ret_read_data   <= read_data;
    ret_store_wstrb <= store_wstrb;
    ret_store_data  <= store_data;
    ret_trap        <= dbg_trap;
    ret_mscratch    <= dbg_mscratch;
    ret_csr_wdata   <= dbg_csr_wdata;
    ret_mstatus     <= dbg_mstatus;
    ret_mtvec       <= dbg_mtvec;
    ret_mepc        <= dbg_mepc;
    ret_mcause      <= dbg_mcause;
    ret_mtval       <= dbg_mtval;
    ret_mie         <= dbg_mie;
    ret_mip         <= dbg_mip;
    ret_mcycle      <= dbg_mcycle;
    ret_minstret    <= dbg_minstret;
    ret_mcycleh     <= dbg_mcycleh;
    ret_minstreth   <= dbg_minstreth;
  end

  always_ff @(posedge clock) begin
    valid_q <= !reset;
    if (reset) order_q <= 64'd0;
    else if (valid_q) order_q <= order_q + 64'd1;
  end

  assign rvfi_valid     = valid_q;
  assign rvfi_order     = order_q;

  assign rd_nonzero     = ret_reg_write && (ret_instr[11:7] != 5'd0);
  assign rvfi_insn      = ret_instr;
  assign rvfi_rs1_addr  = ret_instr[19:15];
  assign rvfi_rs2_addr  = ret_instr[24:20];
  assign rvfi_rs1_rdata = ret_rs1_data;
  assign rvfi_rs2_rdata = ret_rs2_data;
  assign rvfi_rd_addr   = rd_nonzero ? ret_instr[11:7] : 5'd0;
  assign rvfi_rd_wdata  = rd_nonzero ? ret_rd_wdata : 32'd0;

  assign rvfi_mem_addr  = {ret_alu_result[31:2], 2'b00};
  assign rvfi_mem_wmask = ret_store_wstrb;
  assign rvfi_mem_rmask = rmask_c;
  assign rvfi_mem_rdata = ret_read_data;
  assign rvfi_mem_wdata = ret_store_data;

  always_comb begin
    rmask_c = 4'b0000;
    if (ret_instr[6:0] == 7'b0000011) begin
      case (ret_instr[14:12])
        3'b000, 3'b100: rmask_c = 4'b0001 << ret_alu_result[1:0];
        3'b001, 3'b101: rmask_c = 4'b0011 << ret_alu_result[1:0];
        3'b010:         rmask_c = 4'b1111;
        default:        rmask_c = 4'b0000;
      endcase
    end
  end

  assign rvfi_trap     = ret_trap;
  assign rvfi_halt     = 1'b0;
  assign rvfi_intr     = 1'b0;
  assign rvfi_mode     = 2'd3;
  assign rvfi_ixl      = 2'd1;
  assign rvfi_pc_rdata = ret_pc;
  assign rvfi_pc_wdata = pc;

  logic csr_op;
  assign csr_op = ret_instr[6:0] == 7'b1110011 && ret_instr[14:12] != 3'b000;

`ifdef RISCV_FORMAL_CSR_MSCRATCH
  logic is_mscratch;
  assign is_mscratch = csr_op && ret_instr[31:20] == 12'h340;
  assign rvfi_csr_mscratch_rmask = is_mscratch ? 32'hFFFFFFFF : 32'd0;
  assign rvfi_csr_mscratch_wmask = (ret_mscratch != dbg_mscratch) ? 32'hFFFFFFFF : (is_mscratch ? 32'hFFFFFFFF : 32'd0);
  assign rvfi_csr_mscratch_rdata = ret_mscratch;
  assign rvfi_csr_mscratch_wdata = dbg_mscratch;
`endif
`ifdef RISCV_FORMAL_CSR_MSTATUS
  logic is_mstatus;
  assign is_mstatus = csr_op && ret_instr[31:20] == 12'h300;
  assign rvfi_csr_mstatus_rmask = is_mstatus ? 32'hFFFFFFFF : 32'd0;
  assign rvfi_csr_mstatus_wmask = (ret_mstatus != dbg_mstatus) ? 32'hFFFFFFFF : (is_mstatus ? 32'hFFFFFFFF : 32'd0);
  assign rvfi_csr_mstatus_rdata = ret_mstatus;
  assign rvfi_csr_mstatus_wdata = dbg_mstatus;
`endif
`ifdef RISCV_FORMAL_CSR_MTVEC
  logic is_mtvec;
  assign is_mtvec = csr_op && ret_instr[31:20] == 12'h305;
  assign rvfi_csr_mtvec_rmask = is_mtvec ? 32'hFFFFFFFF : 32'd0;
  assign rvfi_csr_mtvec_wmask = (ret_mtvec != dbg_mtvec) ? 32'hFFFFFFFF : (is_mtvec ? 32'hFFFFFFFF : 32'd0);
  assign rvfi_csr_mtvec_rdata = ret_mtvec;
  assign rvfi_csr_mtvec_wdata = dbg_mtvec;
`endif
`ifdef RISCV_FORMAL_CSR_MEPC
  logic is_mepc;
  assign is_mepc = csr_op && ret_instr[31:20] == 12'h341;
  assign rvfi_csr_mepc_rmask = is_mepc ? 32'hFFFFFFFF : 32'd0;
  assign rvfi_csr_mepc_wmask = (ret_mepc != dbg_mepc) ? 32'hFFFFFFFF : (is_mepc ? 32'hFFFFFFFF : 32'd0);
  assign rvfi_csr_mepc_rdata = ret_mepc;
  assign rvfi_csr_mepc_wdata = dbg_mepc;
`endif
`ifdef RISCV_FORMAL_CSR_MCAUSE
  logic is_mcause;
  assign is_mcause = csr_op && ret_instr[31:20] == 12'h342;
  assign rvfi_csr_mcause_rmask = is_mcause ? 32'hFFFFFFFF : 32'd0;
  assign rvfi_csr_mcause_wmask = (ret_mcause != dbg_mcause) ? 32'hFFFFFFFF : (is_mcause ? 32'hFFFFFFFF : 32'd0);
  assign rvfi_csr_mcause_rdata = ret_mcause;
  assign rvfi_csr_mcause_wdata = dbg_mcause;
`endif
`ifdef RISCV_FORMAL_CSR_MTVAL
  logic is_mtval;
  assign is_mtval = csr_op && ret_instr[31:20] == 12'h343;
  assign rvfi_csr_mtval_rmask = is_mtval ? 32'hFFFFFFFF : 32'd0;
  assign rvfi_csr_mtval_wmask = (ret_mtval != dbg_mtval) ? 32'hFFFFFFFF : (is_mtval ? 32'hFFFFFFFF : 32'd0);
  assign rvfi_csr_mtval_rdata = ret_mtval;
  assign rvfi_csr_mtval_wdata = dbg_mtval;
`endif
`ifdef RISCV_FORMAL_CSR_MIE
  logic is_mie;
  assign is_mie = csr_op && ret_instr[31:20] == 12'h304;
  assign rvfi_csr_mie_rmask = is_mie ? 32'hFFFFFFFF : 32'd0;
  assign rvfi_csr_mie_wmask = (ret_mie != dbg_mie) ? 32'hFFFFFFFF : (is_mie ? 32'hFFFFFFFF : 32'd0);
  assign rvfi_csr_mie_rdata = ret_mie;
  assign rvfi_csr_mie_wdata = dbg_mie;
`endif
`ifdef RISCV_FORMAL_CSR_MIP
  logic is_mip;
  assign is_mip = csr_op && ret_instr[31:20] == 12'h344;
  assign rvfi_csr_mip_rmask = is_mip ? 32'hFFFFFFFF : 32'd0;
  assign rvfi_csr_mip_wmask = (ret_mip != dbg_mip) ? 32'hFFFFFFFF : (is_mip ? 32'hFFFFFFFF : 32'd0);
  assign rvfi_csr_mip_rdata = ret_mip;
  assign rvfi_csr_mip_wdata = dbg_mip;
`endif
`ifdef RISCV_FORMAL_CSR_MCYCLE
  logic is_mcycle_lo;
  assign is_mcycle_lo = csr_op && ret_instr[31:20] == 12'hB00;
  logic is_mcycle_hi;
  assign is_mcycle_hi = csr_op && ret_instr[31:20] == 12'hB80;
  assign rvfi_csr_mcycle_rmask = {is_mcycle_hi ? 32'hFFFFFFFF : 32'd0, is_mcycle_lo ? 32'hFFFFFFFF : 32'd0};
  assign rvfi_csr_mcycle_wmask = {is_mcycle_hi ? 32'hFFFFFFFF : 32'd0, is_mcycle_lo ? 32'hFFFFFFFF : 32'd0};
  assign rvfi_csr_mcycle_rdata = {ret_mcycleh, ret_mcycle};
  assign rvfi_csr_mcycle_wdata = {dbg_mcycleh, dbg_mcycle};
`endif
`ifdef RISCV_FORMAL_CSR_MINSTRET
  logic is_minstret_lo;
  assign is_minstret_lo = csr_op && ret_instr[31:20] == 12'hB02;
  logic is_minstret_hi;
  assign is_minstret_hi = csr_op && ret_instr[31:20] == 12'hB82;
  assign rvfi_csr_minstret_rmask = {is_minstret_hi ? 32'hFFFFFFFF : 32'd0, is_minstret_lo ? 32'hFFFFFFFF : 32'd0};
  assign rvfi_csr_minstret_wmask = {is_minstret_hi ? 32'hFFFFFFFF : 32'd0, is_minstret_lo ? 32'hFFFFFFFF : 32'd0};
  assign rvfi_csr_minstret_rdata = {ret_minstreth, ret_minstret};
  assign rvfi_csr_minstret_wdata = {dbg_minstreth, dbg_minstret};
`endif

endmodule
