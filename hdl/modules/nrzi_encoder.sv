module nrzi_encoder (
    input           clk_i,
    input           data_i,
    output          data_o
);
    var bit output_state_r = '0;
    logic output_state_next;

    always_comb begin
        output_state_next = output_state_r ^ data_i;
    end

    always_ff @(posedge clk_i) begin
        output_state_r <= output_state_next;
    end

    assign data_o = output_state_r;
endmodule
