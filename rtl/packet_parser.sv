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

    logic [7:0] byte_count_d, byte_count_q;       // For RECEIVE state
    logic [7:0] tx_byte_count_d, tx_byte_count_q; // For TRANSMIT state
    logic [7:0] lsb_d, lsb_q;
    logic [7:0] msb_d, msb_q;
    logic [7:0] opcode_d, opcode_q;
    logic [7:0] rx_data_prev;

    logic [31:0] add_result;
    logic [31:0] mul_result;
    logic mul_ready;

    // Instantiate modules
    adder add_inst (
        .a_i(operand1_q),
        .b_i(operand2_q),
        .sum_o(add_result)
    );

    bsg_imul_iterative #(.width_p(32)) mul_inst (
        .clk_i(clk_i),
        .reset_i(rst_i),
        .v_i(state_q == COMPUTE && opcode_q == OPCODE_MUL32),
        .ready_and_o(mul_ready),
        .opA_i(operand1_q),
        .signed_opA_i(1'b0),
        .opB_i(operand2_q),
        .signed_opB_i(1'b0),
        .gets_high_part_i(1'b0),
        .v_o(),
        .result_o(mul_result),
        .yumi_i(mul_ready) // Always accept the result
    );

    // Sequential logic
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
            tx_byte_count_q <= 8'b0;
            lsb_q <= 8'b0;
            msb_q <= 8'b0;
            opcode_q <= 8'b0;
            rx_data_prev <= 8'b0;
        end else begin
            for (int i = 0; i < 16; i++) begin
                operand_q[i] <= operand_d[i];
            end
            state_q <= state_d;
            operand1_q <= operand1_d;
            operand2_q <= operand2_d;
            result_q <= result_d;
            byte_count_q <= byte_count_d;
            tx_byte_count_q <= tx_byte_count_d;
            lsb_q <= lsb_d;
            msb_q <= msb_d;
            opcode_q <= opcode_d;
            rx_data_prev <= rx_valid_i ? rx_data_i : rx_data_prev;
        end
    end

    // Combinational logic
    always_comb begin
        // Default values
        tx_data_o = 8'b0;
        tx_valid_o = 1'b0;
        state_d = state_q;
        operand1_d = {operand_q[3], operand_q[2], operand_q[1], operand_q[0]};
        operand2_d = {operand_q[7], operand_q[6], operand_q[5], operand_q[4]};
        result_d = result_q;
        byte_count_d = byte_count_q;
        tx_byte_count_d = tx_byte_count_q;
        lsb_d = lsb_q;
        msb_d = msb_q;
        opcode_d = opcode_q;

        for (int i = 0; i < 16; i++) begin
            operand_d[i] = operand_q[i];
        end

        case (state_q)
            IDLE: begin
                byte_count_d = 8'b0;
                tx_byte_count_d = 8'b0;
                if (rx_valid_i) begin
                    state_d = RECEIVE;
                end
            end

            RECEIVE: begin
                if (rx_valid_i) begin
                    case (byte_count_q)
                        0: opcode_d = rx_data_prev;
                        2: lsb_d = rx_data_prev;
                        3: msb_d = rx_data_prev;
                        default: begin
                            if (byte_count_q >= 4 && byte_count_q < 4 + lsb_q) begin
                                operand_d[byte_count_q - 4] = rx_data_prev;
                            end
                            if (byte_count_q == 4 + lsb_q - 1) begin
                                state_d = COMPUTE;
                            end
                        end
                    endcase
                    byte_count_d = byte_count_q + 1;
                end
            end

            COMPUTE: begin
                case (opcode_q)
                    OPCODE_ECHO: begin
                        for (int i = 0; i < 16; i++) begin
                            if (i < lsb_q) begin
                                result_d[i * 8 +: 8] = operand_q[i];
                            end
                        end
                        state_d = TRANSMIT;
                    end
                    OPCODE_ADD32: begin
                        result_d = add_result;
                        state_d = TRANSMIT;
                    end
                    OPCODE_MUL32: begin
                        if (mul_ready) begin
                            result_d = mul_result;
                            state_d = TRANSMIT;
                        end
                    end
                    default: state_d = IDLE; // Handle unknown opcodes
                endcase
            end

            TRANSMIT: begin
                if (tx_ready) begin
                    tx_data_o = result_q[7:0];
                    tx_valid_o = 1'b1;
                    result_d = result_q >> 8;
                    tx_byte_count_d = tx_byte_count_q + 1;
                    if (tx_byte_count_q == lsb_q - 1) begin
                        state_d = IDLE;
                    end
                end
            end
        endcase
    end

endmodule
