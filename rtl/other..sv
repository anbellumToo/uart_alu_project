    // UART TX instance
    uart_tx #(
        .DATA_WIDTH(8)
    ) uart_tx_inst (
        .clk          (clk_i),
        .rst          (reset_sync),
        .s_axis_tdata (tx_data),
        .s_axis_tvalid(1'b1),
        .s_axis_tready(tx_ready),
        .txd          (txd_internal),
        .busy         (),
        .prescale     (16'd32)
    );
