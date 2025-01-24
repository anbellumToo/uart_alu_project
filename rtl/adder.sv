module adder
  #(parameter width_p = 32)
  (
    input  [width_p-1:0] a_i,
    input  [width_p-1:0] b_i,
    output [width_p:0] sum_o
  );


  wire [width_p:0] carry;
  wire [width_p-1:0] g_i;
  wire [width_p-1:0] p_i;
  assign carry[0] = 1'b0;

  assign p_i = a_i ^ b_i;
  assign g_i = a_i & b_i;

  genvar i;
  generate
    for (i = 0; i < width_p; i = i + 4) begin
      wire [3:0] p, g;
      /* verilator lint_off UNUSEDSIGNAL */
      wire [3:0] c_out;
      /* verilator lint_on UNUSEDSIGNAL */

      localparam int effective_width = (width_p - i < 4) ? (width_p - i) : 4;

      /* verilator lint_off WIDTHEXPAND */
      assign p = p_i[i +: effective_width];
      assign g = g_i[i +: effective_width];
      /* verilator lint_on WIDTHEXPAND */

      CARRY4 carry4_inst (
        .CI(carry[i]),
        .CO(c_out),
        /* verilator lint_off PINCONNECTEMPTY */
        .O(),
        /* verilator lint_on PINCONNECTEMPTY */
        .CYINIT(1'b0),
        .DI(g),
        .S(p)
      );

      assign carry[i+1 +: effective_width] = c_out[effective_width-1:0];
      assign sum_o = {carry[width_p], p_i ^ carry[width_p-1:0]};

    end
  endgenerate


endmodule
