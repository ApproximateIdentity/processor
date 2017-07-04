`timescale 1ns / 1ps

`include "defines.vh"

module hazard_detection_unit(

  load_instruction,
  mem_op,

  instruction0_in,
  instruction1_in,

  first,

  //////////////

  stall0,
  nop0,

  stall1,
  nop1,

  flush0,
  flush1,

  //////////////

  pc0_in,
  pc1_in,

  id0_in,
  id1_in,

  //////////////

  instruction0_out,
  instruction1_out,

  pc0_out,
  pc1_out,

  id0_out,
  id1_out,
  
  );

  input wire [`INST_WIDTH-1:0] load_instruction;
  input wire [`MEM_OP_BITS-1:0] mem_op;

  input wire [`INST_WIDTH-1:0] instruction0_in;
  input wire [`INST_WIDTH-1:0] instruction1_in;

  input wire first;

  //////////////

  input wire [`ADDR_WIDTH-1:0] pc0_in;
  input wire [`ADDR_WIDTH-1:0] pc1_in;

  input wire [`INSTRUCTION_ID_WIDTH-1:0] id0_in;
  input wire [`INSTRUCTION_ID_WIDTH-1:0] id1_in;

  //////////////

  output reg [`NUM_PIPE_MASKS-1:0] stall0;
  output reg [`NUM_PIPE_MASKS-1:0] nop0;

  output reg [`NUM_PIPE_MASKS-1:0] stall1;
  output reg [`NUM_PIPE_MASKS-1:0] nop1;

  output reg [`NUM_PIPE_MASKS-1:0] flush0;
  output reg [`NUM_PIPE_MASKS-1:0] flush1;

  //////////////

  output reg [`ADDR_WIDTH-1:0] pc0_out;
  output reg [`ADDR_WIDTH-1:0] pc1_out;

  output reg [`INSTRUCTION_ID_WIDTH-1:0] id0_out;
  output reg [`INSTRUCTION_ID_WIDTH-1:0] id1_out;

  output reg [`INST_WIDTH-1:0] instruction0_out;
  output reg [`INST_WIDTH-1:0] instruction1_out;

  //////////////

  reg load_stall;
  reg split_stall;
  reg steer_stall;

  reg [`PIPE_BITS-1:0] instruction0_pipe;
  reg [`PIPE_BITS-1:0] instruction1_pipe;

  //////////////

  reg [`NUM_REG_MASKS-1:0] src_mask0;
  reg [`NUM_REG_MASKS-1:0] dst_mask0;

  reg [`NUM_REG_MASKS-1:0] src_mask1;
  reg [`NUM_REG_MASKS-1:0] dst_mask1;

  wire [`OP_CODE_BITS-1:0] opcode0;
  wire [`NUM_REGISTERS_LOG2-1:0] rs0;
  wire [`NUM_REGISTERS_LOG2-1:0] rt0;
  wire [`NUM_REGISTERS_LOG2-1:0] rd0;

  wire [`OP_CODE_BITS-1:0] opcode1;
  wire [`NUM_REGISTERS_LOG2-1:0] rs1;
  wire [`NUM_REGISTERS_LOG2-1:0] rt1;
  wire [`NUM_REGISTERS_LOG2-1:0] rd1;

  wire [`NUM_REGISTERS_LOG2-1:0] load_rt;

  //////////////

  reg [`ADDR_WIDTH-1:0] load_pc0;
  reg [`ADDR_WIDTH-1:0] load_pc1;

  reg [`INSTRUCTION_ID_WIDTH-1:0] load_id0;
  reg [`INSTRUCTION_ID_WIDTH-1:0] load_id1;

  reg [`INST_WIDTH-1:0] load_instruction0;
  reg [`INST_WIDTH-1:0] load_instruction1;

  //////////////

  reg [`ADDR_WIDTH-1:0] split_pc0;
  reg [`ADDR_WIDTH-1:0] split_pc1;

  reg [`INSTRUCTION_ID_WIDTH-1:0] split_id0;
  reg [`INSTRUCTION_ID_WIDTH-1:0] split_id1;

  reg [`INST_WIDTH-1:0] split_instruction0;
  reg [`INST_WIDTH-1:0] split_instruction1;

  //////////////

  reg [`ADDR_WIDTH-1:0] steer_pc0;
  reg [`ADDR_WIDTH-1:0] steer_pc1;

  reg [`INSTRUCTION_ID_WIDTH-1:0] steer_id0;
  reg [`INSTRUCTION_ID_WIDTH-1:0] steer_id1;

  reg [`INST_WIDTH-1:0] steer_instruction0;
  reg [`INST_WIDTH-1:0] steer_instruction1;

  //////////////

  assign opcode0 = instruction0_in[`OPCODE_MSB:`OPCODE_LSB];
  assign rs0 =     instruction0_in[`REG_RS_MSB:`REG_RS_LSB];
  assign rt0 =     instruction0_in[`REG_RT_MSB:`REG_RT_LSB];
  assign rd0 =     instruction0_in[`REG_RD_MSB:`REG_RD_LSB];

  assign opcode1 = instruction1_in[`OPCODE_MSB:`OPCODE_LSB];
  assign rs1 =     instruction1_in[`REG_RS_MSB:`REG_RS_LSB];
  assign rt1 =     instruction1_in[`REG_RT_MSB:`REG_RT_LSB];
  assign rd1 =     instruction1_in[`REG_RD_MSB:`REG_RD_LSB];

  assign load_rt = load_instruction[`REG_RT_MSB:`REG_RT_LSB];

  initial begin
    stall0 <= 0;
    nop0 <= 0;
    stall1 <= 0;
    nop1 <= 0;
    flush0 <= 0;
    flush1 <= 0;

    load_stall = 0;
    split_stall = 0;
    steer_stall = 0;
  end

  always @(*) begin
    if((rs0 == load_rt || rt0 == load_rt) && (mem_op == `MEM_OP_READ)) begin
      load_stall = 1;
    end else if((rs1 == load_rt || rt1 == load_rt) && (mem_op == `MEM_OP_READ)) begin
      load_stall = 1;
    end else begin
      load_stall = 0;
    end
  end

  always @(*) begin
    if (load_stall) begin
      stall0 <= `PIPE_REG_PC | `PIPE_REG_IF_ID;
      flush0 <= `PIPE_REG_ID_EX;

      stall1 <= `PIPE_REG_PC | `PIPE_REG_IF_ID;
      flush1 <= `PIPE_REG_ID_EX;
    end else if (split_stall) begin

      if (first) begin
        stall0 <= `PIPE_REG_PC | `PIPE_REG_IF_ID;
        flush0 <= `PIPE_REG_ID_EX;

        stall1 <= `PIPE_REG_PC;
        flush1 <= `PIPE_REG_IF_ID;
      end else begin
        stall1 <= `PIPE_REG_PC | `PIPE_REG_IF_ID;
        flush1 <= `PIPE_REG_ID_EX;

        stall0 <= `PIPE_REG_PC;
        flush0 <= `PIPE_REG_IF_ID;
      end
    end else begin
      stall1 <= 0;
      flush1 <= 0;

      stall0 <= 0;
      flush0 <= 0;
    end
  end

  always @(*) begin

    casex(opcode0)
     `OP_CODE_NOP: begin
        src_mask0 <= 0;
        dst_mask0 <= 0;
      end
      `OP_CODE_JR: begin
        src_mask0 <= `REG_MASK_RS;
        dst_mask0 <= 0;
      end
      6'b00????: begin // add, sub...
        src_mask0 <= `REG_MASK_RS | `REG_MASK_RT;
        dst_mask0 <= `REG_MASK_RD;
      end
      6'b01????: begin // addi, subi...
        src_mask0 <= `REG_MASK_RS;
        dst_mask0 <= `REG_MASK_RT;
      end
      6'b10????: begin // lw, sw, la, sa
        if(opcode0 == `OP_CODE_LW) begin
          src_mask0 <= `REG_MASK_RS;
          dst_mask0 <= `REG_MASK_RT;
        end else if(opcode0 == `OP_CODE_SW) begin
          src_mask0 <= `REG_MASK_RS | `REG_MASK_RT;
          dst_mask0 <= 0;
        end else if(opcode0 == `OP_CODE_LA) begin
          src_mask0 <= 0;
          dst_mask0 <= `REG_MASK_RT;
        end else if(opcode0 == `OP_CODE_SA) begin
          src_mask0 <= `REG_MASK_RT;
          dst_mask0 <= 0;
        end
      end
      6'b11????: begin // jmp, jo, je ...
        src_mask0 <= 0;
        dst_mask0 <= 0;
      end
    endcase

    casex(opcode1)
     `OP_CODE_NOP: begin
        src_mask1 <= 0;
        dst_mask1 <= 0;
      end
      `OP_CODE_JR: begin
        src_mask1 <= `REG_MASK_RS;
        dst_mask1 <= 0;
      end
      6'b00????: begin // add, sub...
        src_mask1 <= `REG_MASK_RS | `REG_MASK_RT;
        dst_mask1 <= `REG_MASK_RD;
      end
      6'b01????: begin // addi, subi...
        src_mask1 <= `REG_MASK_RS;
        dst_mask1 <= `REG_MASK_RT;
      end
      6'b10????: begin // lw, sw, la, sa
        if(opcode1 == `OP_CODE_LW) begin
          src_mask1 <= `REG_MASK_RS;
          dst_mask1 <= `REG_MASK_RT;
        end else if(opcode1 == `OP_CODE_SW) begin
          src_mask1 <= `REG_MASK_RS | `REG_MASK_RT;
          dst_mask1 <= 0;
        end else if(opcode1 == `OP_CODE_LA) begin
          src_mask1 <= 0;
          dst_mask1 <= `REG_MASK_RT;
        end else if(opcode1 == `OP_CODE_SA) begin
          src_mask1 <= `REG_MASK_RT;
          dst_mask1 <= 0;
        end
      end
      6'b11????: begin // jmp, jo, je ...
        src_mask1 <= 0;
        dst_mask1 <= 0;
      end
    endcase

    if(!load_stall) begin

      if (first) begin

        casex( {src_mask0, dst_mask1} )

          {`REG_MASK_RS | `REG_MASK_RT, `REG_MASK_RT}: begin
            if (rs0 == rt1 || rt0 == rt1) begin
              split_stall = 1;
            end else begin
              split_stall = 0;
            end
          end
          {`REG_MASK_RS | `REG_MASK_RT, `REG_MASK_RD}: begin
            if (rs0 == rd1 || rt0 == rd1) begin
              split_stall = 1;
            end else begin
              split_stall = 0;
            end
          end

          {`REG_MASK_RS, `REG_MASK_RT}: begin
            if (rs0 == rt1) begin
              split_stall = 1;
            end else begin
              split_stall = 0;
            end
          end
          {`REG_MASK_RS, `REG_MASK_RD}: begin
            if (rs0 == rd1) begin
              split_stall = 1;
            end else begin
              split_stall = 0;
            end
          end
          {`REG_MASK_RT, `REG_MASK_RT}: begin
            if (rt0 == rt1) begin
              split_stall = 1;
            end else begin
              split_stall = 0;
            end
          end
          {`REG_MASK_RT, `REG_MASK_RD}: begin
            if (rt0 == rd1) begin
               split_stall = 1;
            end else begin
              split_stall = 0;
            end
          end
          default: begin
            split_stall = 0;
          end
        endcase

      end else begin

        casex( {src_mask1, dst_mask0} )

          {`REG_MASK_RS | `REG_MASK_RT, `REG_MASK_RT}: begin
            if (rs1 == rt0 || rt1 == rt0) begin
              split_stall = 1;
            end else begin
              split_stall = 0;
            end
          end
          {`REG_MASK_RS | `REG_MASK_RT, `REG_MASK_RD}: begin
            if (rs1 == rd0 || rt1 == rd0) begin
              split_stall = 1;
            end else begin
              split_stall = 0;
            end
          end

          {`REG_MASK_RS, `REG_MASK_RT}: begin
            if (rs1 == rt0) begin
              split_stall = 1;
            end else begin
              split_stall = 0;
            end
          end
          {`REG_MASK_RS, `REG_MASK_RD}: begin
            if (rs1 == rd0) begin
              split_stall = 1;
            end else begin
              split_stall = 0;
            end
          end
          {`REG_MASK_RT, `REG_MASK_RT}: begin
            if (rt1 == rt0) begin
              split_stall = 1;
            end else begin
              split_stall = 0;
            end
          end
          {`REG_MASK_RT, `REG_MASK_RD}: begin
            if (rt1 == rd0) begin
              split_stall = 1;
            end else begin
              split_stall = 0;
            end
          end
          default: begin
            split_stall = 0;
          end
        endcase
      end
    end
  end

/*
  always @(*) begin

    casex(opcode0)
      6'b000000: begin
        instruction0_pipe = `PIPE_DONT_CARE;
      end
      6'b00????: begin // add, sub...
        if (opcode0 == `OP_CODE_CMP || opcode0 == `OP_CODE_TEST) begin
          instruction0_pipe = `PIPE_BRANCH;
        end else begin
          instruction0_pipe = `PIPE_DONT_CARE;
        end
      end
      6'b01????: begin // addi, subi...
        if (opcode0 == `OP_CODE_CMPI || opcode0 == `OP_CODE_TESTI) begin
          instruction0_pipe = `PIPE_BRANCH;
        end else begin
          instruction0_pipe = `PIPE_DONT_CARE;
        end        
      end
      6'b10????: begin // lw, sw, la, sa
        instruction0_pipe = `PIPE_MEMORY;
      end
      6'b11????: begin // jmp, jo, je ...
        instruction0_pipe = `PIPE_BRANCH;
      end
    endcase

    casex(opcode1)
      6'b000000: begin
        instruction1_pipe = `PIPE_DONT_CARE;
      end
      6'b00????: begin // add, sub...
        if (opcode1 == `OP_CODE_CMP || opcode1 == `OP_CODE_TEST) begin
          instruction1_pipe = `PIPE_BRANCH;
        end else begin
          instruction1_pipe = `PIPE_DONT_CARE;
        end
      end
      6'b01????: begin // addi, subi...
        if (opcode1 == `OP_CODE_CMPI || opcode1 == `OP_CODE_TESTI) begin
          instruction1_pipe = `PIPE_BRANCH;
        end else begin
          instruction1_pipe = `PIPE_DONT_CARE;
        end        
      end
      6'b10????: begin // lw, sw, la, sa
        instruction1_pipe = `PIPE_MEMORY;
      end
      6'b11????: begin // jmp, jo, je ...
        instruction1_pipe = `PIPE_BRANCH;
      end
    endcase

    case( {instruction0_pipe, instruction1_pipe} )
      {`PIPE_BRANCH, `PIPE_BRANCH}: begin
        if (prev_stall == 0) begin
          instruction0_out = instruction0_in;
          instruction1_out = `NOP_INSTRUCTION;
          pc0_out = pc0_in;
          pc1_out = 0;

          id0_out = id0_in;
          id1_out = 0;

          steer_stall = 1;
          first = 0;
        end else begin
          instruction0_out = instruction1_in;
          instruction1_out = `NOP_INSTRUCTION;
          pc0_out = pc1_in;
          pc1_out = 0;

          id0_out = id1_in;
          id1_out = 0;

          steer_stall = 0;
          first = 0;
        end
      end
      {`PIPE_MEMORY, `PIPE_BRANCH}: begin
        instruction0_out = instruction1_in;
        instruction1_out = instruction0_in;
        pc0_out = pc1_in;
        pc1_out = pc0_in;

        id0_out = id1_in;
        id1_out = id0_in;

        steer_stall = 0;
        first = 1;
      end
      {`PIPE_MEMORY, `PIPE_MEMORY}: begin
        if (prev_stall == 0) begin
          instruction0_out = `NOP_INSTRUCTION;
          instruction1_out = instruction0_in;
          pc0_out = 0;
          pc1_out = pc0_in;

          id0_out = 0;
          id1_out = id0_in;

          steer_stall = 1;
          first = 1;
        end else begin
          instruction0_out = `NOP_INSTRUCTION;
          instruction1_out = instruction1_in;
          pc0_out = 0;
          pc1_out = pc1_in;

          id0_out = 0;
          id1_out = id1_in;

          steer_stall = 0;
          first = 1;
        end
      end
      {`PIPE_MEMORY, `PIPE_DONT_CARE}: begin
        instruction0_out = instruction1_in;
        instruction1_out = instruction0_in;
        pc0_out = pc1_in;
        pc1_out = pc0_in;

        id0_out = id1_in;
        id1_out = id0_in;

        steer_stall = 0;
        first = 1;
      end
      {`PIPE_DONT_CARE, `PIPE_BRANCH}: begin
        instruction0_out = instruction1_in;
        instruction1_out = instruction0_in;
        pc0_out = pc1_in;
        pc1_out = pc0_in;

        id0_out = id1_in;
        id1_out = id0_in;

        steer_stall = 0;
        first = 1;
      end
      default: begin
        instruction0_out = instruction0_in;
        instruction1_out = instruction1_in;
        pc0_out = pc0_in;
        pc1_out = pc1_in;

        id0_out = id0_in;
        id1_out = id1_in;

        steer_stall = 0;
        first = 0;
      end
    endcase
  end
*/

endmodule
