module counter
  #(parameter [31:0] max_val_p = 15,
    parameter width_p = $clog2(max_val_p),
    /* verilator lint_off WIDTHTRUNC */
    parameter [width_p-1:0] reset_val_p = '0
    /* verilator lint_on WIDTHTRUNC */
    )
  (
    input  clk_i,
    input  reset_i,
    input  up_i,
    input  down_i,
    output  [width_p-1:0] count_o,
    output [width_p-1:0] count_n
  );

  localparam [width_p-1:0] max_val_lp = max_val_p[width_p - 1:0];
  logic [width_p-1:0] temp_o, temp_n;

  always_ff @(posedge clk_i) begin
    if (reset_i) begin
      temp_o <= reset_val_p;
    end
    else if (up_i && !down_i) begin
      if (count_o == max_val_lp) begin
        temp_o <= '0;
      end
      else begin
        temp_o <= count_o + 1;
      end
    end
    else if (down_i && !up_i) begin
      if (temp_o == '0) begin
        temp_o <= max_val_lp;
      end
      else begin
        temp_o <= count_o - 1;
      end
    end
  end

  always_comb begin
    if (reset_i) begin
      temp_n = reset_val_p;
    end
    else if (up_i && !down_i) begin
      temp_n = (count_o == max_val_lp) ? '0 : count_o + 1'b1;
    end else begin
      temp_n = count_o;
    end
  end

  assign count_o = temp_o;
  assign count_n = temp_n;

endmodule
