`timescale 1ns / 1ps

module top (
    input wire clk_i,
    input wire rst_i,
    input wire rxd_i,
    output wire txd_o
);

    wire clk_100mhz;
    wire pll_lock;

    pll #(
        .DIVR(4'b0000),
        .DIVF(7'b1000010),
        .DIVQ(3'b011),
        .FLT_RNG(3'b001)
    ) pll_inst (
        .clock_in(clk_i),
        .clock_out(clk_100mhz),
        .locked(pll_lock)
    );

    uart_mod uart_inst (
        .clk_i(clk_100mhz),
        .rst_i(rst_i),
        .rxd_i(rxd_i),
        .txd_o(txd_o),
        .rx_valid(),
        .tx_ready(),
        .rx_data()
    );

endmodule
