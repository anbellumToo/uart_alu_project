`timescale 1ns / 1ps

module uart_runner;

    logic clk_i;
    logic rst_i;
    logic rxd_i;
    wire txd_o;        // Changed to wire
    wire rx_valid;     // Changed to wire
    wire tx_ready;     // Changed to wire
    wire [7:0] rx_data; // Changed to wire
    logic led_o;

    localparam realtime ClockPeriod = 20.0;

    initial begin
        clk_i = 0;
        forever begin
            #(ClockPeriod/2);
            clk_i = !clk_i;
        end
    end

    // Instantiate uart_mod as the DUT
    uart_mod uart_dut (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .rxd_i(rxd_i),
        .txd_o(txd_o),
        .rx_valid(rx_valid),
        .tx_ready(tx_ready),
        .rx_data(rx_data)
    );

    task automatic reset;
        clk_i = '0;
        rst_i = '1;
        rxd_i = '1;

        #10000;

        rst_i = '0;
    endtask

    task send_uart_byte(input logic [7:0] uart_byte);
        integer i;
        begin

            rxd_i = '0;
            #(8680);
            $display("Start bit sent: rxd_i=%b, txd_o=%b, rx_valid=%b, rx_data=%h",
                rxd_i, txd_o, rx_valid, rx_data);


            for (i = 0; i < 8; i = i + 1) begin
                rxd_i = uart_byte[i];
                #(8680);
                $display("Sending bit %0d: rxd_i=%b, txd_o=%b, rx_valid=%b, rx_data=%h",
                        i, rxd_i, txd_o, rx_valid, rx_data);
            end

            rxd_i = '1;
            #(8680);
            $display("Stop bit sent: rxd_i=%b, txd_o=%b, rx_valid=%b, rx_data=%h",
                    rxd_i, txd_o, rx_valid, rx_data);
        end
    endtask

    always @(posedge !rx_valid)
        $info("LED On");

    always @(negedge !rx_valid)
        $info("LED Off");

endmodule
