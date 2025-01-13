`timescale 1ns / 1ps

module uart_tb;

    logic clk_i;
    logic rst_i;
    logic rxd_i;
    logic txd_o;
    logic [7:0] rx_data;
    logic rx_valid;
    logic tx_ready;
    logic tx_valid;
    logic [7:0] tx_data;

    logic debug_rx_valid;
    logic debug_tx_ready;
    logic [7:0] debug_rx_data;

    uart_mod uut (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .rxd_i(rxd_i),
        .txd_o(txd_o),
        .debug_rx_valid(debug_rx_valid),
        .debug_tx_ready(debug_tx_ready),
        .debug_rx_data(debug_rx_data)
    );

    always #10 clk_i = ~clk_i;

task send_uart_byte(input logic [7:0] uart_byte);
    integer i;
    begin

        rxd_i = '0;
        #(8680);
        $display("Start bit sent: rxd_i=%b, txd_o=%b, debug_rx_valid=%b, debug_rx_data=%h",
            rxd_i, txd_o, debug_rx_valid, debug_rx_data);


        for (i = 0; i < 8; i = i + 1) begin
            rxd_i = uart_byte[i];
            #(8680);
            $display("Sending bit %0d: rxd_i=%b, txd_o=%b, debug_rx_valid=%b, debug_rx_data=%h",
                     i, rxd_i, txd_o, debug_rx_valid, debug_rx_data);
        end

        rxd_i = '1;
        #(8680);
        $display("Stop bit sent: rxd_i=%b, txd_o=%b, debug_rx_valid=%b, debug_rx_data=%h",
                 rxd_i, txd_o, debug_rx_valid, debug_rx_data);
    end
endtask

    initial begin
        clk_i = '0;
        rst_i = '1;
        rxd_i = '1;

        #10000;

        rst_i = '0;

        $display("Sending UART data...");
        send_uart_byte(8'h55);
        #100000;
        send_uart_byte(8'hAA);
        #100000;
        send_uart_byte(8'hF0);
        #100000;

        $finish;
    end

    initial begin
        $monitor(
            "Time=%0t | rxd_i=%b | txd_o=%b | rx_valid=%b | rx_data=%h | tx_valid=%b | tx_ready=%b | tx_data=%h",
            $time, rxd_i, txd_o, rx_valid, rx_data, tx_valid, tx_ready, tx_data
        );
    end

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0,uart_tb);
        $dumpvars(1, uut);
    end

endmodule
