module divider (
    input  logic [31:0] operand1,
    input  logic [31:0] operand2,
    output logic [31:0] result
);
    assign result = (operand2 != 0) ? operand1 / operand2 : 32'b0;
endmodule
