`timescale 1ns / 1ps

module uart_alu (
    input [0:0] clk_i,
    input [0:0] rst_i,
    input [0:0] rxd_i,
    input [7:0] tx_data_in,
    input  [0:0] tx_valid_in, // Valid signal for the TX module
    output [0:0] txd_o,
    output [0:0] rx_valid,
    output [0:0] tx_ready,
    output [7:0] rx_data
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

    wire txd_internal;  // TX output from uart_tx
    wire tx_ready_wire; // Handshake signal from TX module
    wire rx_valid_wire; // RX valid signal from uart_alu
    wire [7:0] rx_data_wire;

    // UART TX instance
    uart_tx #(
        .DATA_WIDTH(8)
    ) uart_tx_inst (
        .clk          (clk_i),
        .rst          (reset_sync),
        .s_axis_tdata (tx_data_in),     // Input from the testbench
        .s_axis_tvalid(tx_valid_in),   // Input from the testbench
        .s_axis_tready(tx_ready_wire), // Internal handshake
        .txd          (txd_internal), // Internal TX line
        .busy         (),              // Not used
        .prescale     (16'd54)         // Adjust as needed
    );

    // UART ALU instance
    uart_mod uart_mod_inst (
        .clk_i   (clk_i),
        .rst_i   (reset_sync),
        .rxd_i   (txd_internal),       // Internal TX output to RX input
        .txd_o   (txd_o),              // UART TX line from ALU
        .rx_valid(rx_valid_wire),
        .tx_ready(tx_ready),           // Pass through from ALU
        .rx_data (rx_data_wire)
    );

    // Outputs
    assign rx_valid = rx_valid_wire; // Forward RX valid from ALU
    assign rx_data = rx_data_wire;   // Forward RX data from ALU

endmodule
