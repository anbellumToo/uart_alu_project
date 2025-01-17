module icebreaker (
    input  wire CLK,
    input  wire BTN_N,
    input  wire rxd_i,
    output wire txd_o,
    output wire LEDG_N
);
    wire clk_12 = CLK;
    wire clk_50;

    wire pll_lock;
    wire rx_valid;
    wire tx_ready;
    wire [7:0] rx_data;
    wire led;
    assign LEDG_N = ~led;

    // icepll -i 12 -o 50
    SB_PLL40_PAD #(
        .FEEDBACK_PATH("SIMPLE"),
        .DIVR(4'd0),
        .DIVF(7'd66),
        .DIVQ(3'd4),
        .FILTER_RANGE(3'd1)
    ) pll (
        .LOCK(),
        .RESETB(1'b1),
        .BYPASS(1'b0),
        .PACKAGEPIN(clk_12),
        .PLLOUTGLOBAL(clk_50)
    );

   uart_runner.reset();

    uart_mod uart_inst (
        .clk_i(clk_50),
        .rst_i(BTN_N),
        .rxd_i(rxd_i),
        .txd_o(txd_o),
        .rx_valid(rx_valid),
        .tx_ready(tx_ready),
        .rx_data(rx_data)
    );

    assign led = rxd_i;

endmodule
