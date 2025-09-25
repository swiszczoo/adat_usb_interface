module synchronizer_2stage #(
    parameter       PORT_WIDTH = 1
) (
    input [PORT_WIDTH-1:0]      data_i,
    input                       clk_i,
    output [PORT_WIDTH-1:0]     data_o
);
    var bit [PORT_WIDTH-1:0] data_q = '0;
    var bit [PORT_WIDTH-1:0] data_q2 = '0;

    always_ff @(posedge clk_i) begin
        data_q <= data_i;
        data_q2 <= data_q;
    end

    assign data_o = data_q2;
endmodule
