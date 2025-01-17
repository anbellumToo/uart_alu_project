`timescale 1ns / 1ps

module uart_top (
    input [0:0] clk_i,
    input [0:0] rst_i,
    input [0:0] rxd_i,
    output [0:0] txd_o,
    output [0:0] rx_valid,
    output [0:0] tx_ready,
    output [7:0] rx_data
);

    wire clk_100mhz;
    wire pll_lock;

    SB_PLL40_PAD #(
        .DIVR(4'b0000),
        .DIVF(7'b1000010),
        .DIVQ(3'b011),
        .FILTER_RANGE(3'b001)
    ) pll_inst (
        .PACKAGEPIN(clk_i),
        .PLLOUTCORE(clk_100mhz),
        .LOCK(pll_lock),
        .RESETB(1'b1),
        .BYPASS(1'b0)
    );

    uart_mod uart_inst (
        .clk_i(clk_100mhz),
        .rst_i(rst_i),
        .rxd_i(rxd_i),
        .txd_o(txd_o),
        .rx_valid(rx_valid),
        .tx_ready(tx_ready),
        .rx_data(rx_data)
    );

endmodule
