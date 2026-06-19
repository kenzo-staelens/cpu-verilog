module Hazard32 (
    input [31:0] inst_a,
    input [31:0] inst_b,
    output exec_b
);
    // implementation specific
    // no parameters
    //arg 0MMIOOOO DDDDAAAA bbbbBBBB bbbbbbbb

    // (a != jump) &
    // (b = alu) & 
    // (a != dest) &
    // ((b != dest) or b immediate)

    assign exec_b = (inst_a[30:29]!=2'b10) & (inst_b[30:29]==2'b01) & (inst_a[23:20] != inst_b[19:16]) & (inst_b[28] || (inst_a[23:20] != inst_b[11:8]));
endmodule