module packet_parser (
    input logic clk_i,
    input logic rst_i,
    input logic [7:0] rx_data_i,
    input logic rx_valid_i,
    input logic tx_ready,
    output logic [7:0] tx_data_o,
    output logic tx_valid_o
    );

typedef enum logic [1:0] {
    IDLE,
    RECEIVE,
    COMPUTE,
    TRANSMIT
} state_t;

localparam OPCODE_ECHO = 8'hEC;
localparam OPCODE_ADD32 = 8'hA0;
localparam OPCODE_MUL32 = 8'hA1;
localparam OPCODE_DIV32 = 8'hA2;

state_t state_d, state_q;

logic [31:0] operand1_d, operand1_q;
logic [31:0] operand2_d, operand2_q;
logic [7:0] operand_d [0:15];
logic [7:0] operand_q [0:15];
logic [31:0] result_d, result_q;

logic [7:0] byte_count_d, byte_count_q;
logic [7:0] lsb_d, lsb_q;
logic [7:0] msb_d, msb_q;
logic [7:0] opcode_d, opcode_q;
logic [7:0] rx_data_prev;

logic [127:0] tx_buffer_d, tx_buffer_q;
logic [7:0] tx_byte_count_d, tx_byte_count_q;
logic [7:0] tx_index_d, tx_index_q;

logic mul_valid, div_valid;
logic mul_ready, div_ready;

logic [31:0] add_result, mul_result, div_quotient, div_remainder;

bsg_imul_iterative #(.width_p(32)) mul_inst (
    .clk_i(clk_i),
    .reset_i(rst_i),
    .v_i(mul_valid),
    .ready_and_o(),
    .opA_i(operand1_q),
    .signed_opA_i(1'b0),
    .opB_i(operand2_q),
    .signed_opB_i(1'b0),
    .gets_high_part_i(1'b0),
    .v_o(mul_ready),
    .result_o(mul_result),
    .yumi_i(1'b1)
);

simple_divider #(
    .WIDTH(32)
) div_inst (
    .clk_i(clk_i),
    .rst_i(rst_i),
    .start_i(div_valid),
    .dividend_i(operand1_q),
    .divisor_i(operand2_q),
    .quotient_o(div_quotient),
    .remainder_o(div_remainder),
    .ready_o(div_ready)
);

// bsg_idiv_iterative #(
//     .width_p(32),
//     .bits_per_iter_p(1)
// ) div_inst (
//     .clk_i(clk_i),
//     .reset_i(rst_i),
//     .v_i(div_valid),
//     .ready_and_o(),
//     .dividend_i(operand1_q),
//     .divisor_i(operand2_q),
//     .signed_div_i(1'b0),
//     .v_o(div_ready),
//     .quotient_o(div_quotient),
//     .remainder_o(div_remainder),
//     .yumi_i(1'b1)
// );

always_ff @(posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
        for (int i = 0; i < 16; i++) begin
            operand_q[i] <= 8'h00;
        end
        state_q <= IDLE;
        operand1_q <= 32'b0;
        operand2_q <= 32'b0;
        result_q <= 32'b0;
        byte_count_q <= 8'b0;
        lsb_q <= 8'b0;
        msb_q <= 8'b0;
        opcode_q <= 8'b0;
        rx_data_prev <= 8'b0;
        tx_buffer_q <= 128'b0;
        tx_byte_count_q <= 8'b0;
        tx_index_q <= 8'b0;
    end else begin
        for (int i = 0; i < 16; i++) begin
            operand_q[i] <= operand_d[i];
        end
        state_q <= state_d;
        operand1_q <= operand1_d;
        operand2_q <= operand2_d;
        result_q <= result_d;
        byte_count_q <= byte_count_d;
        lsb_q <= lsb_d;
        msb_q <= msb_d;
        opcode_q <= opcode_d;
        rx_data_prev <= rx_valid_i ? rx_data_i : rx_data_prev;
        tx_buffer_q <= tx_buffer_d;
        tx_byte_count_q <= tx_byte_count_d;
        tx_index_q <= tx_index_d;
    end
end

always_ff @(negedge clk_i) begin
    if (rst_i) begin
        byte_count_d <= 8'b0;
    end else if (state_q == RECEIVE && rx_valid_i) begin
        byte_count_d <= byte_count_q + 1;
    end else if (state_q != RECEIVE) begin
        byte_count_d <= 8'b0;
    end
end

always_comb begin
    tx_data_o = 8'b0;
    tx_valid_o = 1'b0;
    mul_valid = 1'b0;
    div_valid = 1'b0;
    state_d = state_q;

    operand1_d = {operand_q[3], operand_q[2], operand_q[1], operand_q[0]};
    operand2_d = {operand_q[7], operand_q[6], operand_q[5], operand_q[4]};
    result_d = result_q;
    lsb_d = lsb_q;
    msb_d = msb_q;
    opcode_d = opcode_q;

    tx_buffer_d = tx_buffer_q;
    tx_byte_count_d = tx_byte_count_q;
    tx_index_d = tx_index_q;

    add_result = '0;

    for (int i = 0; i < 16; i++) begin
        operand_d[i] = operand_q[i];
    end

    case (state_q)
        IDLE: begin
            result_d = 32'b0;
            tx_valid_o = 1'b0;
            if (rx_valid_i) begin
                state_d = RECEIVE;
            end
        end

        RECEIVE: begin
            case (byte_count_q)
                0: opcode_d = rx_data_prev;
                1: ;
                2: lsb_d = rx_data_prev;
                3: msb_d = rx_data_prev;

                default: begin
                    if (byte_count_q >= 4 && byte_count_q < 4 + lsb_q) begin
                        operand_d[byte_count_q - 4] = rx_data_prev;
                    end
                    if (byte_count_q == 4 + lsb_q - 1) begin
                        state_d = COMPUTE;
                    end else if (msb_q > lsb_q) begin
                        state_d = IDLE;
                    end
                end
            endcase
        end

        COMPUTE: begin
            mul_valid = 1'b0;
            case (opcode_q)
                OPCODE_ECHO: begin
                    tx_buffer_d = 128'b0;
                    for (int i = 0; i < 16; i++) begin
                        if (i < lsb_q) begin
                         tx_buffer_d[i*8 +: 8] = operand_q[i];
                    end
                end
                    tx_byte_count_d = lsb_q;
                    tx_index_d = 0;
                    state_d = TRANSMIT;
                end
                OPCODE_ADD32: begin
                    add_result = operand1_q + operand2_q;
                    tx_buffer_d = {add_result[31:24], add_result[23:16], add_result[15:8], add_result[7:0]};
                    tx_byte_count_d = 4;
                    tx_index_d = 0;
                    state_d = TRANSMIT;
                end
                OPCODE_MUL32: begin
                    mul_valid = 1'b1;
                    if (mul_ready) begin
                        tx_buffer_d = {mul_result[31:24], mul_result[23:16], mul_result[15:8], mul_result[7:0]};
                        tx_byte_count_d = 4;
                        tx_index_d = 0;
                        state_d = TRANSMIT;
                    end else begin
                        state_d = COMPUTE;
                    end
                end
                OPCODE_DIV32: begin
                    div_valid = 1'b1;
                    if (div_ready) begin
                        tx_buffer_d = {div_quotient[31:24], div_quotient[23:16], div_quotient[15:8], div_quotient[7:0],
                                       div_remainder[31:24], div_remainder[23:16], div_remainder[15:8], div_remainder[7:0]};
                        tx_byte_count_d = 8;
                        tx_index_d = 0;
                        state_d = TRANSMIT;
                    end else begin
                        state_d = COMPUTE;
                    end
                end
                 default: begin
                    state_d = IDLE;
                end
            endcase
        end

        TRANSMIT: begin
            if (tx_index_q < tx_byte_count_q) begin
                tx_data_o = tx_buffer_q[tx_index_q * 8 +: 8];
                tx_valid_o = 1'b1;
                if (tx_ready) begin
                    tx_index_d = tx_index_q + 1;
                    if (tx_index_q + 1 == tx_byte_count_q) begin
                        state_d = IDLE;
                    end else begin
                        state_d = TRANSMIT;
                    end
                end
            end else begin
                state_d = IDLE;
            end
        end

        default: state_d = IDLE;
    endcase
end

endmodule
