`timescale 1ns / 1ps

module uart_runner;

    logic clk_i;
    logic rst_i;
    logic rxd_i;
    logic [7:0] tx_data_in;
    logic tx_valid_in;
    wire txd_o;        // Changed to wire
    wire rx_valid;     // Changed to wire
    wire tx_ready;     // Changed to wire
    wire [7:0] rx_data; // Changed to wire

    localparam realtime ClockPeriod = 20.0;

    initial begin
        clk_i = 0;
        forever begin
            #(ClockPeriod/2);
            clk_i = !clk_i;
        end
    end

    // Instantiate uart_mod as the DUT
    uart_alu dut (
        .clk_i        (clk_i),
        .rst_i        (rst_i),
        .tx_data_in   (tx_data_in),   // Data input for TX
        .tx_valid_in  (tx_valid_in), // Valid input for TX
        .rxd_i        (1'b1),        // No external RX input for now
        .txd_o        (txd_o),
        .rx_valid     (rx_valid),
        .tx_ready     (tx_ready),
        .rx_data      (rx_data)
    );

    task automatic reset;
        rst_i <= 0;
        tx_data_in = 8'h00;
        tx_valid_in = 1'b0;
        repeat (10) @(posedge clk_i); // Hold reset for 10 cycles
        rst_i <= 1;
    endtask

    // Task to send data
    task send_uart_byte(input logic [7:0] data);
        begin
            wait (tx_ready);  // Wait for TX to be ready
            @(posedge clk_i);
            tx_data_in <= data;
            tx_valid_in <= 1'b1;
            @(posedge clk_i);
            tx_valid_in <= 1'b0;  // Deassert valid after one cycle
            $display("Sent data: 0x%02h", data);
            #90000;
        end
    endtask

    // Monitor RX data
    always @(posedge clk_i) begin
        if (rx_valid) begin
            $display("Received data: 0x%02h at time %t", rx_data, $time);
        end
    end

endmodule
