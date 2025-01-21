module fifo_1r1w
  #(parameter [31:0] width_p = 8,
    parameter [31:0] depth_log2_p = 8)
  (
    input [0:0] clk_i,
    input [0:0] reset_i,

    input [width_p - 1:0] data_i,
    input [0:0] valid_i,
    output [0:0] ready_o,

    output [0:0] valid_o,
    output [width_p - 1:0] data_o,
    input [0:0] ready_i
  );

  logic last_write, bypass;
  logic [depth_log2_p:0] write_ptr, read_ptr, next_read;
  logic [depth_log2_p:0] last_write_addr;
  logic [width_p-1:0] data_out_reg, last_data_in;


  counter #(.width_p(depth_log2_p + 1), .reset_val_p('0), .max_val_p(32'hFFFFF)) counter_wr (
      .clk_i(clk_i),
      .reset_i(reset_i),
      .up_i(valid_i & ready_o),
      .down_i(1'b0),
      .count_o(write_ptr),
      .count_n()
  );

  counter #(.width_p(depth_log2_p + 1), .reset_val_p('0), .max_val_p(32'hFFFFF)) counter_rd (
      .clk_i(clk_i),
      .reset_i(reset_i),
      .up_i(valid_o & ready_i),
      .down_i(1'b0),
      .count_o(read_ptr),
      .count_n(next_read)
  );

  always_ff @(posedge clk_i) begin
    if (reset_i) begin
      last_data_in <= '0;
      last_write <= '0;
      last_write_addr <= '0;
    end else if (valid_i & ready_o) begin
      last_data_in <= data_i;
      last_write <= '1;
    end else begin
      last_write <= '0;
    end
    last_write_addr <= write_ptr[depth_log2_p:0];
  end

  assign ready_o = !((write_ptr[depth_log2_p-1:0] == read_ptr[depth_log2_p-1:0]) && (write_ptr[depth_log2_p] != read_ptr[depth_log2_p]));
  assign valid_o = !(write_ptr == read_ptr);

  ram_1r1w_sync #(
      .width_p(width_p),
      .depth_p(1 << depth_log2_p),
      .filename_p("memory_init_file.bin")
  ) inst_ram (
      .clk_i(clk_i),
      .reset_i(reset_i),
      .wr_valid_i(valid_i & ready_o),
      .wr_data_i(data_i),
      .wr_addr_i(write_ptr[depth_log2_p-1:0]),
      .rd_valid_i(1'b1),
      .rd_addr_i(next_read[depth_log2_p-1:0]),
      .rd_data_o(data_out_reg)
  );

// if last write = current read
// and if last cycle had a write

  assign bypass = ((read_ptr == last_write_addr) & last_write);

  assign data_o = bypass ? last_data_in : data_out_reg;

endmodule
