`timescale 1ns / 1ps

module uart_tb
  //  import config_pkg::*;
  //  import dv_pkg::*;
    ;
    uart_runner uart_runner();

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0,uart_tb);
        $dumpvars(1, uart_runner.dut);

        uart_runner.reset();

        $display("Starting ALU Tests via UART...");

       // Test ECHO operation: 5
        uart_runner.send_uart_packet(8'hEC, 32'h00000005, 32'h00000000);
        #10000

        // Test ADD operation: 5 + 7
        uart_runner.send_uart_packet(8'hA0, 32'h00000005, 32'h00000007);
        #10000

        // Test MUL operation: 3 * 4
        uart_runner.send_uart_packet(8'hA1, 32'h00000003, 32'h00000004);
                #10000


        // Test DIV operation: 15 / 3
        uart_runner.send_uart_packet(8'hA2, 32'h0000000F, 32'h00000003);
                #10000

        $display("End simulation.");
        $finish;
    end

endmodule
