`timescale 1ns / 1ps

module uart_mod (
    input wire clk_i,
    input wire rst_i,
    input wire rxd_i,
    output wire txd_o
);

    wire [7:0] rx_data;
    wire rx_valid;
    wire tx_ready;
    wire tx_valid;
    wire [7:0] tx_data;

    uart_rx #(
        .DATA_WIDTH(8)
    ) uart_rx_inst (
        .clk(clk_i),
        .rst(rst_i),
        .m_axis_tdata(rx_data),
        .m_axis_tvalid(rx_valid),
        .m_axis_tready(1'b1),
        .rxd(rxd_i),
        .busy(),
        .overrun_error(),
        .frame_error(),
        .prescale(16'd868)
    );

wire tx_ready_internal;
assign tx_ready_internal = tx_ready || ~tx_valid;

uart_tx #(
    .DATA_WIDTH(8)
) uart_tx_inst (
    .clk(clk_i),
    .rst(rst_i),
    .s_axis_tdata(tx_data),
    .s_axis_tvalid(tx_valid),
    .s_axis_tready(tx_ready_internal),
    .txd(txd_o),
    .busy(),
    .prescale(16'd868)
);

endmodule
