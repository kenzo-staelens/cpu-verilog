//~ `New testbench
`timescale  1ns / 1ps

module tb_Hazard;

// Hazard Parameters
parameter PERIOD  = 10;


// Hazard Inputs
reg   [31:0]  inst_a                       = 0 ;
reg   [31:0]  inst_b                       = 0 ;

// Hazard Outputs
wire  exec_b                               ;


Hazard  u_Hazard (
    .inst_a                  ( inst_a  [31:0] ),
    .inst_b                  ( inst_b  [31:0] ),

    .exec_b                  ( exec_b         )
);


`define assert(signal, value, x) \
        if (signal !== value) begin \
            $display("ASSERTION FAILED in %m: signal != value for x "); \
            $finish; \
        end

initial
begin
    // valid
    // alu r1, r2, r3
    inst_a = 32'h20120300;
    // alu r2, r3, r4
    inst_b = 32'h20230400;
    #5 `assert(exec_b, 1, basic valid);

    // jmp
    #10 inst_a = 32'h40120300;
    #10 inst_b = 32'h20230400;
    #15
    `assert(exec_b, 0, JMP A)
    
    // data hazard A
    #20
    inst_a = 32'h20120300;
    inst_b = 32'h20210400;
    #25
    `assert(exec_b, 0, data hazard A)
    
    // hazard B
    #30 inst_b = 32'h20230100;
    #35
    `assert(exec_b, 0, data hazard B)
    
    //hazard B but immediate
    #40 inst_b = 32'h30230100;
    #45
    `assert(exec_b, 1, data Immediate B)
    
    //not alu
    #50 inst_b = 32'h00230400;
    #55
    `assert(exec_b, 0, not ALU B)
    
    

    #100 $finish;
end


initial
begin
    $monitor("a = %h, b = %h, out = %b", inst_a, inst_b, exec_b);
end

endmodule