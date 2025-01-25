module simple_divider #(
    parameter WIDTH = 32
) (
    input logic clk_i,
    input logic rst_i,
    input logic start_i,
    input logic [WIDTH-1:0] dividend_i,
    input logic [WIDTH-1:0] divisor_i,
    output logic [WIDTH-1:0] quotient_o,
    output logic [WIDTH-1:0] remainder_o,
    output logic ready_o
);

    typedef enum logic [1:0] {
        IDLE,
        CALCULATE,
        DONE
    } state_t;

    state_t state_q, state_d;

    logic [WIDTH-1:0] dividend_q, dividend_d;
    logic [WIDTH-1:0] divisor_q, divisor_d;
    logic [WIDTH-1:0] quotient_q, quotient_d;
    logic [WIDTH-1:0] remainder_q, remainder_d;
    logic [$clog2(WIDTH):0] count_q, count_d;

    always_ff @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            state_q <= IDLE;
            dividend_q <= 0;
            divisor_q <= 0;
            quotient_q <= 0;
            remainder_q <= 0;
            count_q <= 0;
        end else begin
            state_q <= state_d;
            dividend_q <= dividend_d;
            divisor_q <= divisor_d;
            quotient_q <= quotient_d;
            remainder_q <= remainder_d;
            count_q <= count_d;
        end
    end

    always_comb begin
        state_d = state_q;
        dividend_d = dividend_q;
        divisor_d = divisor_q;
        quotient_d = quotient_q;
        remainder_d = remainder_q;
        count_d = count_q;
        ready_o = 0;

        case (state_q)
            IDLE: begin
                if (start_i) begin
                    dividend_d = dividend_i;
                    divisor_d = divisor_i;
                    quotient_d = 0;
                    remainder_d = 0;
                    count_d = WIDTH;
                    state_d = CALCULATE;
                end
            end

            CALCULATE: begin
                if (count_q > 0) begin
                    remainder_d = {remainder_q[WIDTH-2:0], dividend_q[WIDTH-1]};
                    dividend_d = {dividend_q[WIDTH-2:0], 1'b0};

                    if (remainder_d >= divisor_q) begin
                        remainder_d = remainder_d - divisor_q;
                        quotient_d = {quotient_q[WIDTH-2:0], 1'b1};
                    end else begin
                        quotient_d = {quotient_q[WIDTH-2:0], 1'b0};
                    end

                    count_d = count_q - 1;
                end else begin
                    state_d = DONE;
                end
            end

            DONE: begin
                ready_o = 1;
                if (!start_i) begin
                    state_d = IDLE;
                end
            end
        endcase
    end

    assign quotient_o = quotient_q;
    assign remainder_o = remainder_q;

endmodule
