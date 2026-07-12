module control_decoder (
    input  logic [6:0] op,
    output logic       reg_write,
    output logic [2:0] imm_src,
    output logic       alu_src,
    output logic       mem_write,
    output logic [1:0] result_src,
    output logic       branch,
    output logic       jump,
    output logic [1:0] alu_op
);

  // opcodes
  localparam logic [6:0] OpcodeOp = 7'b0110011;
  localparam logic [6:0] OpcodeOpImm = 7'b0010011;
  localparam logic [6:0] OpcodeLoad = 7'b0000011;
  localparam logic [6:0] OpcodeStore = 7'b0100011;
  localparam logic [6:0] OpcodeBranch = 7'b1100011;
  localparam logic [6:0] OpcodeJal = 7'b1101111;
  localparam logic [6:0] OpcodeJalr = 7'b1100111;
  localparam logic [6:0] OpcodeLui = 7'b0110111;
  localparam logic [6:0] OpcodeAuipc = 7'b0010111;

  // imm_src encoding: 0=I, 1=S, 2=B, 3=U, 4=J
  localparam logic [2:0] ImmI = 3'd0;
  localparam logic [2:0] ImmS = 3'd1;
  localparam logic [2:0] ImmB = 3'd2;
  localparam logic [2:0] ImmU = 3'd3;
  localparam logic [2:0] ImmJ = 3'd4;

  // result_src: 0=alu, 1=mem read, 2=pc+4
  localparam logic [1:0] ResAlu = 2'd0;
  localparam logic [1:0] ResMem = 2'd1;
  localparam logic [1:0] ResPc4 = 2'd2;

  // alu_op
  localparam logic [1:0] AluOpAdd = 2'b00;  // address / pc math
  localparam logic [1:0] AluOpBranch = 2'b01;  // compare for branches
  localparam logic [1:0] AluOpFunct = 2'b10;  // decode from funct3/funct7

  always_comb begin
    reg_write  = 1'b0;
    imm_src    = ImmI;
    alu_src    = 1'b0;
    mem_write  = 1'b0;
    result_src = ResAlu;
    branch     = 1'b0;
    jump       = 1'b0;
    alu_op     = AluOpAdd;

    case (op)
      OpcodeOp: begin  // add, sub, and, or, xor, sll, srl, sra, slt, sltu
        reg_write = 1'b1;
        alu_src   = 1'b0;
        alu_op    = AluOpFunct;
      end

      OpcodeOpImm: begin  // addi, andi, ori, xori, slli, srli, srai, slti, sltiu
        reg_write = 1'b1;
        imm_src   = ImmI;
        alu_src   = 1'b1;
        alu_op    = AluOpFunct;
      end

      OpcodeLoad: begin  // lw
        reg_write  = 1'b1;
        imm_src    = ImmI;
        alu_src    = 1'b1;
        result_src = ResMem;
        alu_op     = AluOpAdd;
      end

      OpcodeStore: begin  // sw
        imm_src   = ImmS;
        alu_src   = 1'b1;
        mem_write = 1'b1;
        alu_op    = AluOpAdd;
      end

      OpcodeBranch: begin  // beq, bne, blt, bge, bltu, bgeu
        imm_src = ImmB;
        alu_src = 1'b0;
        branch  = 1'b1;
        alu_op  = AluOpBranch;
      end

      OpcodeJal: begin  // jal
        reg_write  = 1'b1;
        imm_src    = ImmJ;
        result_src = ResPc4;
        jump       = 1'b1;
      end

      OpcodeJalr: begin  // jalr
        reg_write  = 1'b1;
        imm_src    = ImmI;
        alu_src    = 1'b1;
        result_src = ResPc4;
        jump       = 1'b1;
        alu_op     = AluOpAdd;  // alu computes rs1 + imm as the target
      end

      OpcodeLui: begin  // lui
        reg_write = 1'b1;
        imm_src   = ImmU;
        alu_src   = 1'b1;
        alu_op    = AluOpAdd;  // 0 + immU via the SrcA=0 mux
      end

      OpcodeAuipc: begin  // auipc
        reg_write = 1'b1;
        imm_src   = ImmU;
        alu_src   = 1'b1;
        alu_op    = AluOpAdd;  // needs pc on the alu's a input
      end

      default: begin
        reg_write  = 1'b0;
        imm_src    = 3'bxxx;
        alu_src    = 1'bx;
        mem_write  = 1'b0;
        result_src = 2'bxx;
        branch     = 1'b0;
        jump       = 1'b0;
        alu_op     = 2'bxx;
      end
    endcase
  end

endmodule
