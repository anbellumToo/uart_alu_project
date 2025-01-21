`ifndef BINPATH
 `define BINPATH ""
`endif
module ram_1r1w_sync
  #(parameter [31:0] width_p = 8
  ,parameter [31:0] depth_p = 32
  ,parameter filename_p = "memory_init_file.bin")

  (input [0:0] clk_i
  ,input [0:0] reset_i

  ,input [0:0] wr_valid_i
  ,input [width_p-1:0] wr_data_i
  ,input [$clog2(depth_p) - 1 : 0] wr_addr_i

  ,input [0:0] rd_valid_i
  ,input [$clog2(depth_p) - 1 : 0] rd_addr_i
  ,output [width_p-1:0] rd_data_o);

  logic [width_p-1:0] mem [0:depth_p-1];
  logic [width_p-1:0] temp_rd_data;

  always_ff @(posedge clk_i) begin
    if (reset_i) begin
      temp_rd_data <= '0;
    end else if (rd_valid_i) begin
      temp_rd_data <= mem[rd_addr_i];
    end

    if (wr_valid_i & ~reset_i) begin
      mem[wr_addr_i] <= wr_data_i;
    end
  end

  assign rd_data_o = temp_rd_data;

endmodule
