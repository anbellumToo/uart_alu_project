`timescale 1ns / 1ps

module uart_mod (
    input [0:0] clk_i,
    input [0:0] rst_i,
    input [0:0] rxd_i,
    output [0:0] txd_o
);

wire rx_valid, tx_ready;
wire [7:0] rx_data;

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
    .prescale(16'd32)
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
    .prescale(16'd32)
);

endmodule
