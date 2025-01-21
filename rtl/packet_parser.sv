module packet_parser (
    input logic clk_i,
    input logic rst_i,
    input logic [7:0] rx_data_i,
    input logic rx_valid_i,
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
    logic [31:0] result_d, result_q;

    logic [7:0] byte_count_d, byte_count_q;
    logic [7:0] lsb_d, lsb_q;
    logic [7:0] msb_d, msb_q;
    logic [7:0] opcode_d, opcode_q;
    logic [7:0] rx_data_prev;

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            state_q <= IDLE;
            operand1_q <= 32'b0;
            operand2_q <= 32'b0;
            result_q <= 32'b0;
            byte_count_q <= 8'b0;
            lsb_q <= 8'b0;
            msb_q <= 8'b0;
            opcode_q <= 8'b0;
            rx_data_prev <= 8'b0;
        end else begin
            state_q <= state_d;
            operand1_q <= operand1_d;
            operand2_q <= operand2_d;
            result_q <= result_d;
            byte_count_q <= byte_count_d;
            lsb_q <= lsb_d;
            msb_q <= msb_d;
            opcode_q <= opcode_d;
            rx_data_prev <= rx_data_i;
        end
    end

    always_ff @(negedge clk_i) begin
        if (rst_i) begin
            byte_count_d <= 8'b0;
        end else if (state_q == RECEIVE && rx_valid_i && (rx_data_i != rx_data_prev)) begin
            byte_count_d <= byte_count_q + 1;
        end else if (state_q != RECEIVE) begin
            byte_count_d <= 8'b0;
        end
    end

    always_comb begin
        state_d = state_q;
        operand1_d = operand1_q;
        operand2_d = operand2_q;
        result_d = result_q;
        lsb_d = lsb_q;
        msb_d = msb_q;
        opcode_d = opcode_q;

        tx_data_o = 8'b0;
        tx_valid_o = 1'b0;

        case (state_q)
            IDLE: begin
                if (rx_valid_i) begin
                    state_d = RECEIVE;
                end
            end

            RECEIVE: begin
                if (rx_valid_i) begin
                    case (byte_count_q)
                        0: opcode_d = rx_data_prev; // Capture opcode
                        1: ; // Reserved byte, do nothing
                        2: lsb_d = rx_data_prev; // Capture LSB of length
                        3: msb_d = rx_data_prev; // Capture MSB of length

                        // Capture operand1
                        4: operand1_d[7:0] = rx_data_prev;
                        5: operand2_d[7:0] = rx_data_prev;

                        default: begin
                            if (msb_q > lsb_q) begin
                                state_d = IDLE; // Reset to IDLE state on error
                            end else if ((byte_count_q >= 6) || (opcode_q == 8'hEC && byte_count_q == 5)) begin
                                state_d = COMPUTE; // Transition to COMPUTE
                            end
                        end
                    endcase
                end
            end

            COMPUTE: begin
                case (opcode_q)
                    OPCODE_ECHO: result_d = echo(operand1_q);
                    OPCODE_ADD32: result_d = operand1_q + operand2_q;
                    OPCODE_MUL32: result_d = operand1_q * operand2_q;
                    OPCODE_DIV32: result_d = (operand2_q != 0) ? (operand1_q / operand2_q) : 32'b0;
                endcase
                state_d = TRANSMIT;
            end

            TRANSMIT: begin
                tx_data_o = result_q[7:0];
                tx_valid_o = 1'b1;
                result_d = result_q >> 8;
                if (result_q == 0) begin
                    state_d = IDLE;
                end
            end
        endcase
    end

    function logic [31:0] echo(input logic [31:0] message);
        echo = message;
    endfunction

endmodule
