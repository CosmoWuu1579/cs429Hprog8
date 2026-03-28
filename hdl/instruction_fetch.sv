module instruction_fetch (
    input wire clk,
    input wire reset,
    input wire ooo_signal,
    input wire [63:0] ooo_address,
    output wire [63:0] pc_address
);
    reg [63:0] pc;
    assign pc_address = pc;
    // TODO double check the above 
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