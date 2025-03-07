`ifndef HEXPATH
 `define HEXPATH ""
`endif

module ram_1r1w_async
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

  assign rd_data_o = mem[rd_addr_i];

  always_ff @(posedge clk_i) begin
    if (wr_valid_i && ~reset_i) begin
      mem[wr_addr_i] <= wr_data_i;
      $display("%m: Writing mem[%0d] = %h", wr_addr_i, wr_data_i);
    end
  end

endmodule
