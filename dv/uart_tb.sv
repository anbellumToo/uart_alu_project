`timescale 1ns / 1ps

module uart_tb
  //  import config_pkg::*;
  //  import dv_pkg::*;
    ;
    uart_runner uart_runner();

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0,uart_tb);
        $dumpvars(1, uart_runner.uart_dut);

        uart_runner.reset();

        $display("Sending UART data...");

        uart_runner.send_uart_byte(8'h55);
        uart_runner.send_uart_byte(8'hAA);
        uart_runner.send_uart_byte(8'hF0);

        $display("End simulation.");
        $finish;
    end

endmodule
