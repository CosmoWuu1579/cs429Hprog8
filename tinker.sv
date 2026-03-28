`include "hdl/alu.sv"
`include "hdl/instruction_decoder.sv"
`include "hdl/instruction_fetch.sv"
`include "hdl/memory.sv"
`include "hdl/reg_file.sv"
module tinker_core(
    input clk,
    input reset
);
    wire [4:0] opcode;
    wire [63:0] rd_data;
    wire [63:0] rs_data;
    wire [63:0] rt_data;
    wire [63:0] stack_pointer;
    wire [11:0] L_data;
    wire [63:0] memory_read_alu;
    wire [63:0] pc_address;
    wire [63:0] memory_pointer;
    wire memory_write;
    wire [63:0] memory_data_to_write;
    wire ooo_signal;
    wire [63:0] ooo_address;
    wire [63:0] reg_out_value;
    wire reg_write;
    wire [31:0] instruction;
    wire [4:0] d;
    wire [4:0] s;
    wire [4:0] t;
    

    // always@(posedge clk or posedge reset) begin
    alu u_alu(
    .opcode (opcode),
    .rd (rd_data),
    .rs (rs_data),
    .rt (rt_data),
    .stack_pointer (stack_pointer),
    .L (L_data),
    .memory_value (memory_read_alu),
    .pc (pc_address),
    .memory_pointer (memory_pointer),
    .memory_write (memory_write), // decide if you want to write
    .memory_data_to_write (memory_data_to_write),
    .ooo_signal (ooo_signal),
    .ooo_address (ooo_address),
    .reg_out_value (reg_out_value),
    .reg_write (reg_write)
    );


    instruction_decoder u_decoder (
        .instruction (instruction),
        .opcode (opcode),
        .d (d),
        .s (s),
        .t (t),
        .L (L_data)
    );

    instruction_fetch u_fetch(
        .clk (clk),
        .reset (reset),
        .ooo_signal (ooo_signal),
        .ooo_address (ooo_address),
        .pc_address (pc_address)
    );

    memory u_memory(
    .clk (clk),
    .pc (pc_address),
    .alu_data (memory_data_to_write),
    .alu_pointer (memory_pointer),
    .write (memory_write),
    .instruction (instruction),
    .address_value (memory_read_alu)
    );

    register_file u_reg_file(
        .clk (clk),
        .reset (reset),
        .write (reg_write),
        .data_write (reg_out_value),
        .d (d),
        .s (s),
        .t (t),
        .rd (rd_data),
        .rs (rs_data),
        .rt (rt_data),
        .stack_pointer (stack_pointer)
    );

    // end
endmodule