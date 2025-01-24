module icebreaker (
    input  wire CLK,
    input  wire BTN_N,
    input  wire rxd_i,
    output wire txd_o,
    output wire LEDG_N
);
    wire clk_12 = CLK;        // Incoming 12 MHz clock
    wire clk_16;              // PLL-generated 16 MHz clock

    // icepll -i 12 -o 30
    SB_PLL40_PAD #(
        .FEEDBACK_PATH("SIMPLE"),
        .DIVR(4'd0),
        .DIVF(7'd84),
        .DIVQ(3'd6),
        .FILTER_RANGE(3'd1)
    ) pll (
        .LOCK(pll_lock),
        .RESETB(1'b1),
        .BYPASS(1'b0),
        .PACKAGEPIN(clk_12),
        .PLLOUTGLOBAL(clk_16)
    );

    // UART ALU instance
    uart_alu uart_inst (
        .clk_i       (clk_16),      // 50 MHz clock from PLL
        .rst_i       (BTN_N),       // Reset signal from button
        .rxd_i       (rxd_i),       // UART RX input
        .txd_o       (txd_o),       // UART TX output
    );

    assign LEDG_N = ~BTN_N;

endmodule
