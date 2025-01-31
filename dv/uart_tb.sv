`timescale 1ns / 1ps
/* verilator lint_off MODDUP */
module uart_tb;
/* verilator lint_on MODDUP */
    uart_runner runner();

    int total_errors = 0;
    int echo_errors = 0;
    int add_errors = 0;
    int mul_errors = 0;
    int div_errors = 0;

    localparam test_count = 100;

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, uart_tb);
        $dumpvars(1, runner.uart_dut.parser_inst);

        runner.reset();
        $display("\n=== Starting Tests ===");

        test_operation(8'hec, test_count);
        test_operation(8'ha0, test_count);
        test_operation(8'ha1, test_count);
        test_operation(8'ha2, test_count);

        $display("\n=== Test Results ===");
        $display("Total errors: %0d", total_errors);
        $display("Echo: %0d, Add: %0d, Mul: %0d, Div: %0d",
                echo_errors, add_errors, mul_errors, div_errors);
        $display("=== Tests complete ===");
        $display("Test_count: %0d", test_count);
        $finish;
    end

    task automatic test_operation(input logic [7:0] opcode, input int num_tests);
        automatic logic [7:0] payload[];
        automatic logic [7:0] received[];

        $display("\n==== Testing %s ====", get_opname(opcode));

        for(int i=0; i<num_tests; i++) begin
            runner.reset();
            $display("\n[TEST %0d]", i+1);
            generate_random_payload(opcode, payload);

            runner.send_uart_packet(
                .opcode(opcode),
                .reserved(8'h00),
                .length_lsb(payload.size() % 256),
                .length_msb(8'h00),
                .payload(payload)
            );

            runner.receive_uart_packet(opcode, payload, received);
            verify_response(opcode, payload, received);

            #2000;
        end
    endtask

    function string get_opname(input logic [7:0] opcode);
        case(opcode)
            8'hec: return "ECHO";
            8'ha0: return "ADD";
            8'ha1: return "MUL";
            8'ha2: return "DIV";
            default: return "UNKNOWN";
        endcase
    endfunction

    function void generate_random_payload (input logic [7:0] opcode, ref logic [7:0] payload[]);
    automatic int length = (opcode == 8'ha2) ? 8 : 16;
    payload = new[length];

    foreach (payload[i]) begin
        payload[i] = $urandom_range(8'h1, 8'hFF);
    end

    for (int i = 0; i < 8; i += 4) begin
        if (opcode == 8'ha2) begin
            payload[i + 1] = 8'h00;
            payload[i + 2] = 8'h00;
            payload[i + 3] = 8'h00;
        end
    end

    for (int i = length; i < 16; i += 4) begin
        if (opcode == 8'ha1) begin
            payload = new[16];
            payload[i + 0] = 8'h01;
            payload[i + 1] = 8'h00;
            payload[i + 2] = 8'h00;
            payload[i + 3] = 8'h00;
        end else if (opcode == 8'ha0) begin
            payload = new[16];
            payload[i + 0] = 8'h00;
            payload[i + 1] = 8'h00;
            payload[i + 2] = 8'h00;
            payload[i + 3] = 8'h00;
        end
    end

    $display("[GEN] Payload size: %0d", payload.size());
endfunction

    function void verify_response(
        input logic [7:0] opcode,
        input logic [7:0] payload[],
        input logic [7:0] received[]
    );
        logic [31:0] a, b, c, d, result, expected;
        logic [31:0] quotient, remainder;
        logic [31:0] quotient_received, remainder_received;

        $display("[VERIFY] Starting verification...");

        if(opcode == 8'hec) begin
            if(payload.size() != received.size()) begin
                echo_errors++;
                $display("## ERROR Echo length: sent %0d vs received %0d",
                       payload.size(), received.size());
            end
            else foreach(payload[i]) begin
                if(payload[i] !== received[i]) begin
                    echo_errors++;
                    $display("## ERROR Data @%0d: sent 0x%h vs received 0x%h",
                           i, payload[i], received[i]);
                end
            end
        end
        else begin
            a = {payload[3], payload[2], payload[1], payload[0]};
            b = {payload[7], payload[6], payload[5], payload[4]};
            c = {payload[11], payload[10], payload[9], payload[8]};
            d = {payload[15], payload[14], payload[13], payload[12]};

            $display("[VERIFY] Operands: A=0x%h (%0d), B=0x%h (%0d), C=0x%h (%0d), D=0x%h (%0d)", a, a, b, b, c, c, d, d);

            quotient = (a / b);
            remainder = (a % b);

            case(opcode)
                8'ha0: expected = (a + b + c + d) & 32'hFFFFFFFF;
                8'ha1: expected = (a * b * c * d) & 32'hFFFFFFFF;
            endcase

            if(received.size() >= 4) begin
                result = {received[3], received[2], received[1], received[0]};

                quotient_received = {received[7], received[6], received[5], received[4]};
                remainder_received = {received[3], received[2], received[1], received[0]};

                if (opcode == 8'ha0 || opcode == 8'ha1) begin
                    $display("[VERIFY] Expected: 0x%h (%0d), Received: 0x%h (%0d)", expected, expected, result, result);
                    $display("[RAW] Received bytes: 0x%h 0x%h 0x%h 0x%h | 0x%h 0x%h 0x%h 0x%h",
                    received[0], received[1], received[2], received[3],
                    received[4], received[5], received[6], received[7]);
                end


                if (opcode == 8'ha2) begin
                    $display("[VERIFY] Expected Quotient:  0x%h (%0d), Remainder: 0x%h (%0d)",
                    quotient, quotient, remainder, remainder);
                    $display("[VERIFY] Received Quotient:  0x%h (%0d), Remainder: 0x%h (%0d)",
                    quotient_received, quotient_received, remainder_received, remainder_received);
                    $display("[RAW] Received bytes: 0x%h 0x%h 0x%h 0x%h | 0x%h 0x%h 0x%h 0x%h",
                    received[0], received[1], received[2], received[3],
                    received[4], received[5], received[6], received[7]);
                end

                if(result !== expected) begin
                    case(opcode)
                        8'ha0: add_errors++;
                        8'ha1: mul_errors++;
                    endcase
                end

                if (opcode == 8'ha2 & ((quotient_received !== quotient) || (remainder_received !== remainder))) begin
                    div_errors++;
                    $display("[VERIFY] Expected Quotient:  0x%h (%0d), Remainder: 0x%h (%0d)",
                             quotient, quotient, remainder, remainder);
                    $display("[VERIFY] Received Quotient:  0x%h (%0d), Remainder: 0x%h (%0d)",
                             quotient_received, quotient_received, remainder_received, remainder_received);
                             $display("[RAW] Received bytes: 0x%h 0x%h 0x%h 0x%h | 0x%h 0x%h 0x%h 0x%h",
                             received[0], received[1], received[2], received[3],
                             received[4], received[5], received[6], received[7]);

                end
            end else begin
                case(opcode)
                    8'ha0: add_errors++;
                    8'ha1: mul_errors++;
                    8'ha2: div_errors++;
                endcase
                $display("## ERROR Missing response!");
            end
        end
        total_errors = echo_errors + add_errors + mul_errors + div_errors;
    endfunction
endmodule
