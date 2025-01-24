module multiplier
  #(parameter width_p = 8) // width_p represents the bit-width of m and r
   (
    input [0:0] clk_i,
    input [0:0] reset_i,
    // Input Interface
    input [0:0] valid_i,
    output [0:0] ready_o,
    input [width_p - 1:0] a_i,  // m, the multiplicand
    input [width_p - 1:0] b_i,  // r, the multiplier
    // Output Interface
    output [0:0] valid_o,
    input [0:0] ready_i,
    output [(2 * width_p) - 1:0] result_o
   );

  typedef enum logic [1:0] {
    LOAD, CALCULATE, DONE
  } state_t;

  state_t state, next_state;

  logic signed [width_p : 0] a_ext, a_z;
  logic signed [(2 * width_p) + 1 : 0] product, a_reg, next_a_reg, next_product, s_reg, next_s_reg, temp;
  logic signed [1:0] booth_bits;
  logic signed [width_p - 1:0] count;

  counter #(.width_p(width_p), .reset_val_p(0)) counter_inst (
    .clk_i(clk_i),
    .reset_i(reset_i | state == LOAD),
    .up_i(state == CALCULATE), // Count up during calculation
    .down_i(1'b0),
    .count_o(count)
  );

  assign a_z = {a_i[width_p-1], a_i};
  assign a_ext = (~a_z+ 1'b1); //{{a_i[width_p - 1]}, a_i};

  always_ff @(posedge clk_i) begin
    if (reset_i) begin
      state <= LOAD;
    end else begin
      product <= next_product;
      s_reg <= next_s_reg;
      a_reg <= next_a_reg;
      state <= next_state;
    end
  end

  // Next State Logic
  always_comb begin
    next_state = state;
    case(state)
      LOAD: begin
        next_a_reg = {{a_z}, {(width_p + 1){1'b0}}};
        next_s_reg = {{a_ext}, {(width_p + 1){1'b0}}};
        next_product = {{(width_p + 1){1'b0}}, {b_i}, 1'b0};
        //booth_bits = product[1:0];
        if (valid_i)
          next_state = CALCULATE;
      end
      CALCULATE: begin
        /* verilator lint_off WIDTHEXPAND */
        if (count == (width_p - 1))
        /* verilator lint_on WIDTHEXPAND */
           next_state = DONE;
        booth_bits = product[1:0];
        case (booth_bits)
          2'b01: temp = product + a_reg;
          2'b10: temp = product + s_reg;
          default: temp = product;
        endcase
        next_product = temp >>> 1;
      end
      DONE: begin
        if (ready_i)
          next_state = LOAD;
      end
      default: next_state = state;
    endcase
  end

  assign result_o = product[(2 * width_p):1];
  assign ready_o = (state == LOAD);
  assign valid_o = (state == DONE);

endmodule
