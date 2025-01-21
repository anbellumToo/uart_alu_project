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



  always @(posedge clk_i) begin
    if (tx_ready && tx_valid) begin
        $display("UART TX Sending: %h", tx_data);
    end
 end

  always @(posedge rx_data) begin
      $display("RX data changed: %h", rx_data);
  end


module packet_parser (
    input logic clk_i,
    input logic rst_i,
    input logic [7:0] rx_data_i,
    input logic rx_valid_i,
    output logic [7:0] tx_data_o,
    output logic tx_valid_o,
    output logic rx_ready_o,
    input logic tx_ready_i
);

    typedef enum logic [2:0] {
        IDLE,
        READ_OPCODE,
        READ_RESERVED,
        READ_LENGTH_LSB,
        READ_LENGTH_MSB,
        READ_DATA
    } state_t;

    localparam logic [7:0] ECHO_OPCODE = 8'hec;

    state_t state, next_state;
    logic [7:0] opcode, reserved;
    logic [15:0] length;
    logic [7:0] data [0:255];
    logic [7:0] data_index;

    logic data_ready;

    always_ff @(posedge clk_i or negedge rst_i) begin
        if (!rst_i) begin
            state <= IDLE;
            opcode <= 8'h00;
            reserved <= 8'h00;
            length <= 16'h0000;
            data_index <= 8'h00;
            data_ready <= 1'b0;
        end else begin
            state <= next_state;
            data_ready <= rx_valid_i && rx_ready_o;
            if (data_ready) begin
                case (state)
                    IDLE: begin
                        // Do nothing
                    end
                    READ_OPCODE: begin
                        opcode <= rx_data_i;
                    end
                    READ_RESERVED: begin
                        reserved <= rx_data_i;
                    end
                    READ_LENGTH_LSB: begin
                        length[7:0] <= rx_data_i;
                    end
                    READ_LENGTH_MSB: begin
                        length[15:8] <= rx_data_i;
                    end
                    READ_DATA: begin
                        data[data_index] <= rx_data_i;
                        data_index <= data_index + 1;
                    end
                endcase
            end
        end
    end

    always_comb begin
        next_state = state;
        case (state)
            IDLE: begin
                if (data_ready) begin
                    next_state = READ_OPCODE;
                end
            end
            READ_OPCODE: begin
                if (data_ready) begin
                    next_state = READ_RESERVED;
                end
            end
            READ_RESERVED: begin
                if (data_ready) begin
                    next_state = READ_LENGTH_LSB;
                end
            end
            READ_LENGTH_LSB: begin
                if (data_ready) begin
                    next_state = READ_LENGTH_MSB;
                end
            end
            READ_LENGTH_MSB: begin
                if (data_ready) begin
                if (data_index == length) begin
                    next_state = READ_DATA;
                end
                end
            end
            READ_DATA: begin
                if (data_index == length - 1) begin
                    next_state = IDLE;
                end
            end
        endcase
    end

    always_ff @(posedge clk_i) begin
        if (!rst_i) begin
            tx_data_o <= 8'h00;
            tx_valid_o <= 1'b0;
        end else begin
            tx_valid_o <= 1'b0; // Default to not valid
            if (state == READ_DATA && data_index == length - 1) begin
                if (opcode == ECHO_OPCODE) begin // Echo opcode
                        tx_data_o <= data[data_index];
                        data_index <= data_index + 1;
            end
        end
    end
end

    assign rx_ready_o = (state != IDLE) && (state != READ_DATA || data_index < length - 1);

endmodule


                        for (int i = lsb_d, i <= msb_d, i++) begin
                                4 + i =
                        end
