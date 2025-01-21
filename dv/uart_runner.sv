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

    // Task for sending a structured UART packet
    task automatic send_uart_packet(
        input logic [7:0] opcode,
        input logic [31:0] operand1,
        input logic [31:0] operand2
    );
        logic [15:0] length;
        logic [7:0] uart_byte;
        integer i;

        // Packet length calculation (opcode + reserved + length + operands)
        length = 4 + 8; // 4 header bytes + 8 operand bytes

        begin
            $display("Sending UART Packet - Opcode: %h, Operand1: %h, Operand2: %h", opcode, operand1, operand2);

            // Send Opcode
            send_uart_byte(opcode);

            // Send Reserved Byte
            send_uart_byte(8'h00);

            // Send Length (LSB then MSB)
            send_uart_byte(length[7:0]);
            send_uart_byte(length[15:8]);

            // Send Operand1 (LSB first)
            for (i = 0; i < 4; i = i + 1) begin
                uart_byte = operand1[i * 8 +: 8];
                send_uart_byte(uart_byte);
            end

            // Send Operand2 (LSB first)
            for (i = 0; i < 4; i = i + 1) begin
                uart_byte = operand2[i * 8 +: 8];
                send_uart_byte(uart_byte);
            end

            $display("Packet Sent.");
        end
    endtask
endmodule
