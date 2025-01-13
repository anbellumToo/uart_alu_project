module elastic
  #(parameter [31:0] width_p = 8
  /* verilator lint_off WIDTHTRUNC */
   ,parameter [0:0] datapath_gate_p = 0
   ,parameter [0:0] datapath_reset_p = 0
   /* verilator lint_on WIDTHTRUNC */
   )
  (input [0:0] clk_i
  ,input [0:0] reset_i

  ,input [width_p - 1:0] data_i
  ,input [0:0] valid_i
  ,output [0:0] ready_o

  ,output [0:0] valid_o
  ,output [width_p - 1:0] data_o
  ,input [0:0] ready_i
  );

  logic [width_p-1:0] data_r;
  logic full_r;

  assign ready_o = !full_r || (ready_i && valid_o);
  assign valid_o = full_r;

  always_ff @(posedge clk_i or posedge reset_i) begin
    if (reset_i) begin
      if (datapath_reset_p) begin
        data_r <= '0;
        full_r <= 1'b0;
      end else begin
        full_r <= 1'b0;
      end
    end else begin

      if (~datapath_gate_p && ready_o) begin
        data_r <= data_i;
      end

      if (valid_i && ready_o) begin
        if (datapath_gate_p) begin
          data_r <= valid_i ? data_i : data_r;
        end else begin
          data_r <= data_i;
        end
        full_r <= 1'b1;
      end else if (ready_i && valid_o) begin
        full_r <= 1'b0;
      end
    end
  end

  assign data_o = data_r;

endmodule
