module uart_mod
  #(parameter DATA_WIDTH_P  = 8,
    parameter PRESCALE_P    = 16'd17,
    parameter FIFO_DEPTH_LOG2_P = 4 // Adjust the depth as needed
  )
  (
    input  wire              clk_i,
    input  wire              rst_i,
    input  wire              rxd_i,
    output wire              txd_o
  );

  wire                     rx_valid;
  wire [DATA_WIDTH_P-1:0]  rx_data;
  wire                     rx_ready;

  wire                     tx_valid_fifo; // FIFO valid output
  wire [DATA_WIDTH_P-1:0]  tx_data_fifo;  // FIFO data output
  wire                     tx_ready_fifo; // FIFO ready input

  wire                     tx_valid;     // To uart_tx
  wire [DATA_WIDTH_P-1:0]  tx_data;      // To uart_tx
  wire                     tx_ready;     // From uart_tx

  // UART RX instance
  uart_rx #(
    .DATA_WIDTH(DATA_WIDTH_P)
  ) rx_inst (
    .clk           (clk_i),
    .rst           (rst_i),
    .rxd           (rxd_i),
    .m_axis_tdata  (rx_data),
    .m_axis_tvalid (rx_valid),
    .m_axis_tready (tx_ready),
    .prescale      (PRESCALE_P),
    .busy          (),
    .overrun_error (),
    .frame_error   ()
  );

  // FIFO instance for TX data
  fifo_1r1w #(
    .width_p(DATA_WIDTH_P),
    .depth_log2_p(FIFO_DEPTH_LOG2_P)
  ) tx_fifo (
    .clk_i         (clk_i),
    .reset_i       (rst_i),
    .data_i        (tx_data),
    .valid_i       (tx_valid),
    .ready_i       (tx_ready),
    .ready_o       (tx_ready_fifo),
    .data_o        (tx_data_fifo),
    .valid_o       (tx_valid_fifo)
  );

  // UART TX instance
  uart_tx #(
    .DATA_WIDTH(DATA_WIDTH_P)
  ) tx_inst (
    .clk           (clk_i),
    .rst           (rst_i),
    .s_axis_tdata  (tx_data_fifo),
    .s_axis_tvalid (tx_valid_fifo),
    .s_axis_tready (tx_ready),
    .txd           (txd_o),
    .busy          (),
    .prescale      (PRESCALE_P)
  );

  packet_parser parser_inst (
    .clk_i         (clk_i),
    .rst_i         (rst_i),
    .rx_valid_i    (rx_valid),
    .rx_data_i     (rx_data),
    .tx_data_o     (tx_data),
    .tx_ready      (tx_ready_fifo), // Connect to FIFO ready signal
    .tx_valid_o    (tx_valid)       // Connect to FIFO valid input
  );

endmodule


// `timescale 1ns / 1ps

// module uart_mod (
//     input [0:0] clk_i,
//     input [0:0] rst_i,
//     input [0:0] rxd_i,
//     output [0:0] txd_o
// );

// wire rx_valid, tx_ready;
// wire [7:0] rx_data;

// uart_rx #(
//     .DATA_WIDTH(8)
// ) uart_rx_inst (
//     .clk(clk_i),
//     .rst(rst_i),
//     .m_axis_tdata(rx_data),
//     .m_axis_tvalid(rx_valid),
//     .m_axis_tready(tx_ready),
//     .rxd(rxd_i),
//     .busy(),
//     .overrun_error(),
//     .frame_error(),
//     .prescale(16'd17)
// );

// uart_tx #(
//     .DATA_WIDTH(8)
// ) uart_tx_inst (
//     .clk(clk_i),
//     .rst(rst_i),
//     .s_axis_tdata(rx_data),
//     .s_axis_tvalid(rx_valid),
//     .s_axis_tready(tx_ready),
//     .txd(txd_o),
//     .busy(),
//     .prescale(16'd17)
// );

// endmodule
