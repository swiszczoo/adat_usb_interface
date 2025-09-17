/*
 * This module detects zeroes on input signal line and holds them for time specified in
 * COUNTER_VAL parameter
 */
module sample_and_hold_zero #(
    parameter COUNTER_VAL = 1
) (
    input       clk_i,
    input       signal_i,
    output      signal_o
);
    localparam BITS = $clog2(COUNTER_VAL + 1);

    var bit [BITS-1:0] counter_r = '0;
    logic [BITS-1:0] counter_next;

    var bit signal_r = '0;
    logic signal_next;

    always_comb begin
        if (counter_r > 0) begin
            signal_next = '0;
            counter_next = counter_r - 1;
        end else begin
            signal_next = signal_i;
            counter_next = signal_i ? 0 : COUNTER_VAL;
        end
    end

    always_ff @(posedge clk_i) begin
        counter_r <= counter_next;
        signal_r <= signal_next;
    end

    assign signal_o = signal_r;
endmodule
