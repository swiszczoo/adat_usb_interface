module adat_encoder #(
    parameter CIRC_BUF_BITS=3
) (
    input                           clk_x4_i,
    input                           ram_data_i,
    input [CIRC_BUF_BITS-1:0]       last_good_frame_idx_i,

    output [CIRC_BUF_BITS-1+8:0]    ram_read_addr_o,
    output                          adat_o
);
    typedef enum bit {
        StOutputZeros,
        StOutputData
    } transmitter_state_e;

endmodule
