Implements a simple UART echo using uart_rx and uart_tx submodules.

rst_i: Reset signal (active high).
rxd_i: UART receive input pin.
Outputs:
txd_o: UART transmit output pin.

UART RX:
Configured for 8-bit data width.
Uses a prescale value of 868 (supports 115200 baud rate at a 50 MHz clock).

UART TX:
Configured for 8-bit data width.
Transmits data received via RX.
Handles backpressure for the TX path with a tx_ready_internal signal.
