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

    localparam realtime ClockPeriod = 33.0;

    initial begin
        clk_i = 0;
        forever begin
            #(ClockPeriod/2);
            clk_i = !clk_i;
        end
    end

    uart_alu uart_dut (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .rxd_i(rxd_i),
        .txd_o(txd_o)
    );

task automatic reset;
    rst_i <= 0;
    @(posedge clk_i);
    rst_i <= 1;
endtask

    task send_uart_byte(input logic [7:0] uart_byte);
        integer i;
        begin

            rxd_i = '0;
            #(8680);
            $display("Start bit sent: rxd_i=%b, txd_o=%b",
                rxd_i, txd_o);

            for (i = 0; i < 8; i = i + 1) begin
                rxd_i = uart_byte[i];
                #(8680);
                $display("Sending bit %0d: rxd_i=%b, txd_o=%b",
                        i, rxd_i, txd_o);
            end

            rxd_i = '1;
            #(8680);
            $display("Stop bit sent: rxd_i=%b, txd_o=%b",
                    rxd_i, txd_o);
        end
    endtask

    task send_uart_packet(
        input logic [7:0] opcode,             // Opcode field
        input logic [7:0] reserved,           // Reserved field
        input logic [7:0] length_lsb,         // Length LSB (byte count)
        input logic [7:0] length_msb,         // Length MSB (byte count)
        input logic [7:0] payload [0:15]      // Payload data (up to 16 bytes)
    );
        integer i;
        integer data_length;

        begin
            send_uart_byte(opcode);

            // Send Reserved Byte
            send_uart_byte(reserved);

            // Send Length (LSB then MSB for little-endian)
            send_uart_byte(length_lsb);
            send_uart_byte(length_msb);

            // Calculate data length
            data_length = {length_msb, length_lsb}; // Combine MSB and LSB

            // Send Payload Bytes
            for (i = 0; i < data_length; i = i + 1) begin
                send_uart_byte(payload[i]);
            end

            $display("Packet Sent - Opcode: %0h, Reserved: %0h, Length: %0d, Payload: %p",
                    opcode, reserved, data_length, payload);

           #(8680 * 10); // Adjust as necessary, e.g., 10 bit times

        end
    endtask


endmodule
