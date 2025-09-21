module synchronizer_2stage (
    input           data_i,
    input           clk_i,
    output          data_o
);
    var bit data_q = '0;
    var bit data_q2 = '0;

    always_ff @(posedge clk_i) begin
        data_q <= data_i;
        data_q2 <= data_q;
    end

    assign data_o = data_q2;
endmodule
