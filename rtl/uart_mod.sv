`timescale 1ns / 1ps

module uart_mod (
    input wire clk_i,
    input wire rst_i,
    input wire rxd_i,
    output wire debug_rx_valid,
    output wire debug_tx_ready,
    output wire [7:0] debug_rx_data,
    output wire txd_o
);

wire [7:0] rx_data;
wire [7:0] tx_data;
wire rx_valid;
wire tx_ready;
wire tx_valid;

assign debug_rx_valid = rx_valid;
assign debug_tx_ready = tx_ready;
assign debug_rx_data = rx_data;

uart_rx #(
    .DATA_WIDTH(8)
) uart_rx_inst (
    .clk(clk_i),
    .rst(rst_i),
    .m_axis_tdata(rx_data),
    .m_axis_tvalid(rx_valid),
    .m_axis_tready(tx_ready),
    .rxd(rxd_i),
    .busy(),
    .overrun_error(),
    .frame_error(),
    .prescale(16'd54)
);

uart_tx #(
    .DATA_WIDTH(8)
) uart_tx_inst (
    .clk(clk_i),
    .rst(rst_i),
    .s_axis_tdata(rx_data),
    .s_axis_tvalid(rx_valid),
    .s_axis_tready(tx_ready),
    .txd(txd_o),
    .busy(),
    .prescale(16'd54)
);

endmodule
