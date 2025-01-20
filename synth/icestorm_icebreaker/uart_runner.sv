module uart_runner;

    reg CLK;
    reg BTN_N = 0;
    reg RX = 1;
    wire TX;
    wire LEDG_N;

    initial begin
        CLK = 0;
        forever begin
            #41.666ns; // 12MHz
            CLK = !CLK;
        end
    end

    logic pll_out;
    initial begin
        pll_out = 0;
        forever begin
            #16.660ns; // 50 MHz
            pll_out = !pll_out;
        end
    end
    assign icebreaker.pll.PLLOUTCORE = pll_out;

    icebreaker icebreaker (.*);

    task automatic reset;
        BTN_N = '1;
        #10000;
        BTN_N <= '0;
    endtask

    always @(posedge !LEDG_N) $info("LED On");
    always @(negedge !LEDG_N) $info("LED Off");

endmodule
