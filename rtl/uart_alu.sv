`timescale 1ns / 1ps

module uart_alu (
    input [0:0] clk_i,
    input [0:0] rst_i,
    input [0:0] rxd_i,
    output [0:0] txd_o
);

    logic [0:0] reset_sync_pre, reset_sync, reset_inv;

    always_ff @(posedge clk_i) begin
        reset_sync_pre <= rst_i;
    end

    always_ff @(posedge clk_i) begin
        reset_inv <= ~reset_sync_pre;
    end

    always_ff @(posedge clk_i) begin
        reset_sync <= reset_inv;
    end

    // UART ALU instance
    uart_mod uart_mod_inst (
        .clk_i   (clk_i),
        .rst_i   (reset_sync),
        .rxd_i   (rxd_i),
        .txd_o   (txd_o)
    );

endmodule
