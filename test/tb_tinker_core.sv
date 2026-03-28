`include "tinker.sv"

module tb_tinker_core;
    reg clk, reset;

    tinker_core core (
        .clk   (clk),
        .reset (reset)
    );

    always #5 clk = ~clk;

    // Helper: load a 32-bit instruction word into memory at byte address addr
    task load_instruction;
        input [63:0] addr;
        input [31:0] instr;
        begin
            core.memory.bytes[addr]   = instr[31:24];
            core.memory.bytes[addr+1] = instr[23:16];
            core.memory.bytes[addr+2] = instr[15:8];
            core.memory.bytes[addr+3] = instr[7:0];
        end
    endtask

    // Helper: build a 32-bit R-type instruction
    // Format: [31:27]=opcode [26:22]=rd [21:17]=rs [16:12]=rt [11:0]=L
    function [31:0] instr_r;
        input [4:0] op, rd, rs, rt;
        input [11:0] L;
        instr_r = {op, rd, rs, rt, L};
    endfunction

    integer pass = 0, fail = 0;

    task check64;
        input [63:0] got, expected;
        input [255:0] label;
        begin
            if (got !== expected) begin
                $display("FAIL [%s]: got %h, expected %h", label, got, expected);
                fail = fail + 1;
            end else begin
                $display("PASS [%s]", label);
                pass = pass + 1;
            end
        end
    endtask

    // Run N clock cycles
    task run_cycles;
        input integer n;
        integer i;
        begin
            for (i = 0; i < n; i++) @(posedge clk);
            #1; // small settle time after last edge
        end
    endtask

    initial begin
        clk = 0; reset = 1;

        // -------------------------------------------------------
        // Test 1: ADD r1, r2, r3  (r1 = r2 + r3)
        //   Load r2=10 via ADDI, r3=20 via ADDI, then ADD
        // -------------------------------------------------------

        // addi r2, r2, 10  -> opcode 0x19, rd=r2, L=10
        load_instruction(64'h2000, instr_r(5'h19, 5'd2, 5'd0, 5'd0, 12'd10));
        // addi r3, r3, 20  -> opcode 0x19, rd=r3, L=20
        load_instruction(64'h2004, instr_r(5'h19, 5'd3, 5'd0, 5'd0, 12'd20));
        // add  r1, r2, r3  -> opcode 0x18, rd=r1, rs=r2, rt=r3
        load_instruction(64'h2008, instr_r(5'h18, 5'd1, 5'd2, 5'd3, 12'd0));
        // infinite loop: branch to self  opcode 0x0a (brL), L=sign-extend offset -4
        // We'll just use 4 NOPs (default case) after and stop checking
        load_instruction(64'h200c, instr_r(5'h0, 5'd0, 5'd0, 5'd0, 12'd0)); // NOP (AND r0 = r0 & r0)

        // Release reset, run 4 cycles (one per instruction)
        @(posedge clk); reset = 0;
        run_cycles(4);

        check64(core.reg_file.registers[2], 64'd10, "r2=10 after ADDI");
        check64(core.reg_file.registers[3], 64'd20, "r3=20 after ADDI");
        check64(core.reg_file.registers[1], 64'd30, "r1=r2+r3=30 after ADD");

        // -------------------------------------------------------
        // Test 2: Reset clears registers, PC goes back to 0x2000
        // -------------------------------------------------------
        reset = 1; @(posedge clk); #1; reset = 0;

        check64(core.reg_file.registers[1], 64'd0,    "r1 cleared on reset");
        check64(core.reg_file.registers[31], 64'd524288, "r31=MEM_SIZE on reset");

        // -------------------------------------------------------
        // Test 3: Store then Load
        //   addi r5, r5, 0x2100   (address to store to)
        //   addi r6, r6, 42       (value to store)
        //   store: opcode 0x13, rs=r6, L=0, base=r5
        //   load:  opcode 0x10, rd=r7, rs=r5, L=0
        // -------------------------------------------------------

        // addi r5, r5, 0x100  (base address offset from stack)
        load_instruction(64'h2000, instr_r(5'h19, 5'd5, 5'd0, 5'd0, 12'h100));
        // addi r6, r6, 42
        load_instruction(64'h2004, instr_r(5'h19, 5'd6, 5'd0, 5'd0, 12'd42));
        // store r6 -> mem[r5 + 0]: opcode 0x13, rs=r6, L=0  (rd field used as base in store)
        // store: memory_data_to_write=rs, memory_pointer = rs + sign_ext(L)
        // Actually looking at alu.sv opcode 0x13: data=rs, pointer=rs+L
        // We want to store to a known address. Let's store r6 at mem[r5+0].
        // opcode=0x13, rd=r6(data source / also pointer base), rs=r6, L=0
        load_instruction(64'h2008, instr_r(5'h13, 5'd0, 5'd6, 5'd0, 12'd0));
        // load r7, mem[r6+0]: opcode 0x10, rd=r7, rs=r6, L=0
        load_instruction(64'h200c, instr_r(5'h10, 5'd7, 5'd6, 5'd0, 12'd0));
        // NOP
        load_instruction(64'h2010, instr_r(5'h0, 5'd0, 5'd0, 5'd0, 12'd0));

        run_cycles(5);

        check64(core.reg_file.registers[7], 64'd42, "r7=42 after store+load");

        $display("\n%0d passed, %0d failed", pass, fail);
        $finish;
    end

    // Optional: dump waveform for GTKWave
    initial begin
        $dumpfile("sim/tb_tinker_core.vcd");
        $dumpvars(0, tb_tinker_core);
    end
endmodule
