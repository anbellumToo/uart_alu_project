`timescale 1ns / 1ps

module uart_tb;

    uart_runner uart_runner();

    logic [7:0] echo_payload [0:15];
    logic [7:0] mul_payload [0:15];
    logic [7:0] div_payload [0:15];
    logic [7:0] add_payload [0:15];

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, uart_tb);
        $dumpvars(1, uart_runner.uart_dut);

        uart_runner.reset();

        $display("Starting ALU Tests via UART...");

        // ECHO: [236, 0, 2, 0, 104, 105]
        echo_payload = '{default: 8'h00};
        echo_payload[0] = 8'h68; // 'h'
        echo_payload[1] = 8'h69; // 'i'
        uart_runner.send_uart_packet(8'hec, 8'h00, 8'h02, 8'h00, echo_payload);
        #1000000;

        // MUL: [161, 0, 8, 0, 4, 0, 0, 0, 6, 0, 0, 0]
        mul_payload = '{default: 8'h00};
        mul_payload[0] = 8'h04; mul_payload[4] = 8'h06; // Operands 4 and 6
        uart_runner.send_uart_packet(8'ha1, 8'h00, 8'h08, 8'h00, mul_payload);
        #1000000;

        // DIV: [162, 0, 8, 0, 15, 0, 0, 0, 5, 0, 0, 0]
        div_payload = '{default: 8'h00};
        div_payload[0] = 8'h0F; div_payload[4] = 8'h05; // Operands 15 and 5
        uart_runner.send_uart_packet(8'ha2, 8'h00, 8'h08, 8'h00, div_payload);
        #1000000;

        // ADD: [160, 0, 8, 0, 2, 0, 0, 0, 3, 0, 0, 0]
        add_payload = '{default: 8'h00};
        add_payload[0] = 8'h02; add_payload[4] = 8'h03; // Operands 2 and 3
        uart_runner.send_uart_packet(8'ha0, 8'h00, 8'h08, 8'h00, add_payload);
        #1000000;

        $display("End simulation.");
        $finish;
    end

endmodule
