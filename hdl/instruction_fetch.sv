module instruction_fetch (
    input wire clk,
    input wire reset,
    input wire ooo_signal,
    input wire [63:0] ooo_address,
    output reg [63:0] pc
);
    initial begin 
        pc = 64'h2000;
    end 
    
    always @(posedge clk) begin 
        if (reset) pc <= 64'h2000;
        else begin
            if (ooo_signal) pc <= ooo_address;
            else pc <= pc + 4;
        end
    end 

endmodule