`timescale 1ns / 1ps
/* verilator lint_off MODDUP */
module uart_runner;
/* verilator lint_on MODDUP */
    logic clk_i;
    logic rst_i;
    wire txd_o;
    logic rxd_i;
    logic tx_busy;
    localparam PRESCALE = 17;
    localparam realtime ClockPeriod = 62.5;

    initial begin
        clk_i = 0;
        forever #(ClockPeriod/2) clk_i = !clk_i;
    end

    uart_mod uart_dut (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .rxd_i(rxd_i),
        .txd_o(txd_o)
    );

    uart_rx #(.DATA_WIDTH(8)) tb_rx (
        .clk(clk_i),
        .rst(rst_i),
        .rxd(txd_o),
        .m_axis_tdata(rx_data),
        .m_axis_tvalid(rx_valid),
        .m_axis_tready(1'b1),
        .busy(),
        .overrun_error(),
        .frame_error(),
        .prescale(PRESCALE)
    );

    uart_tx #(.DATA_WIDTH(8)) tb_tx (
        .clk(clk_i),
        .rst(rst_i),
        .s_axis_tdata(tx_data),
        .s_axis_tvalid(tx_valid),
        .s_axis_tready(tx_ready),
        .txd(rxd_i),
        .busy(tx_busy),
        .prescale(PRESCALE)
    );

    logic [7:0] tx_data;
    logic tx_valid;
    logic tx_ready;
    logic [7:0] rx_data;
    logic rx_valid;

    task automatic reset;
        $display("[TB] Resetting...");
        rst_i = 1;
        tx_valid = 0;
        tx_data = '0;
        repeat(20) @(posedge clk_i);
        rst_i = 0;
        repeat(20) @(posedge clk_i);
        $display("[TB] Reset complete");
    endtask

    task automatic send_uart_byte(input logic [7:0] data);
    begin
            tx_valid = 1;
            tx_data = data;
            $display("[TX] Sending byte: 0x%h", data);
            repeat(1300) @(posedge clk_i);
            tx_valid = 0;
            tx_data = '0;
    end
endtask

    task automatic send_uart_packet(
        input logic [7:0] opcode,
        input logic [7:0] reserved,
        input logic [7:0] length_lsb,
        input logic [7:0] length_msb,
        input logic [7:0] payload []
    );
        $display("[TX] Starting packet:");
        $display("  OP: 0x%h, reserved: %h, lsb: %h, msb: %h, payload: %h", opcode, reserved, length_lsb, length_msb, payload);

        send_uart_byte(opcode);
        $display("[TX] Sent Opcode");

        send_uart_byte(reserved);
        $display("[TX] Sent Reserved");

        send_uart_byte(length_lsb);
        $display("[TX] Sent lsb");

        send_uart_byte(length_msb);
        $display("[TX] Sent msb");

        foreach(payload[i]) begin
            send_uart_byte(payload[i]);
            $display("[TX] Sent payload byte %0d: 0x%h", i, payload[i]);
        end

        $display("[TX] Packet complete");
        repeat(100000) @(posedge clk_i);

    endtask

    task automatic receive_uart_packet(
        input logic [7:0] opcode,
        input logic [7:0] payload[],
        output logic [7:0] data[]
    );
        int expected_bytes = (opcode == 8'hec) ? payload.size() :
                            (opcode == 8'ha2) ? 8 : 4;

        $display("[RX] Waiting for %0d bytes...", expected_bytes);

        begin
          #100000
            if(rx_valid) begin
                data = rx_data;
                $display("[RX] Received byte %0d: 0x%h",
                        data.size(), rx_data);
            end
        end
    endtask
endmodule
