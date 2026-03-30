module memory (
    input wire clk,
    input wire [63:0] pc,
    input wire [63:0] alu_data,
    input wire [63:0] alu_pointer,
    input wire write,
    output reg [31:0] instruction,
    output reg [63:0] address_value
);
    localparam MEM_SIZE = 524288;
    reg [7:0] bytes [0:MEM_SIZE-1];
    integer i;
    initial begin
        for (i = 0; i < MEM_SIZE; i = i + 1)
            bytes[i] = 8'h00;
    end
    always @(pc, alu_pointer, alu_data, write) begin
        instruction = {bytes[pc + 3], bytes[pc + 2], bytes[pc + 1], bytes[pc]};
        address_value = {bytes[alu_pointer + 7], bytes[alu_pointer + 6], bytes[alu_pointer + 5], bytes[alu_pointer + 4],
                bytes[alu_pointer + 3], bytes[alu_pointer + 2], bytes[alu_pointer + 1], bytes[alu_pointer]};
    end
    
    always @(posedge clk) begin
        if (write) begin
            bytes[alu_pointer + 7] <= alu_data[63:56];
            bytes[alu_pointer + 6] <= alu_data[55:48];
            bytes[alu_pointer + 5] <= alu_data[47:40];
            bytes[alu_pointer + 4] <= alu_data[39:32];
            bytes[alu_pointer + 3] <= alu_data[31:24];
            bytes[alu_pointer + 2] <= alu_data[23:16];
            bytes[alu_pointer + 1] <= alu_data[15:8];
            bytes[alu_pointer] <= alu_data[7:0];
        end
    end
endmodule