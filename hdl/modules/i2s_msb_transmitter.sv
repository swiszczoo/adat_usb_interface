module i2s_msb_transmitter #(
    parameter CIRC_BUF_BITS=3
) (
    input                           clk_x4_i,
    input                           ram_data_i,
    input                           resync_req_i,
    input [CIRC_BUF_BITS-1:0]       last_good_frame_idx_i,

    output [CIRC_BUF_BITS-1+8:0]    ram_read_addr_o,
    output                          i2s_running_o,
    output                          i2s_bclk_o,
    output                          i2s_lrclk_o,
    output reg                      i2s_data_ro
);
    typedef enum bit [1:0] {
        StOutputNothing,
        StOutputZeros,
        StOutputData
    } output_state_e;

    var bit [CIRC_BUF_BITS-1:0] read_frame_r = '0;
    logic [CIRC_BUF_BITS-1:0] read_frame_next;

    var bit [7:0] read_addr_lo_r = '0;
    logic [7:0] read_addr_lo_next = read_addr_lo_r + 8'b1;

    var bit [2:0] missed_frames_r = '0;
    logic [2:0] missed_frames_next;

    logic soon_next_frame = read_addr_lo_r == 8'hff;
    logic new_frame_available = last_good_frame_idx_i != read_frame_r;

    output_state_e output_state = StOutputNothing;
    output_state_e output_state_next;

    var bit [1:0] clk_counter_r;
    wire clk_main_tick_next = clk_counter_r[1] | clk_counter_r[0];
    var bit clk_main_tick_nr;

    always_ff @(posedge clk_x4_i) begin
        clk_counter_r <= clk_counter_r + 2'b1;
        clk_main_tick_nr <= clk_main_tick_next;
    end

    always_comb begin
        output_state_next = output_state;
        read_frame_next = read_frame_r;
        missed_frames_next = missed_frames_r;

        if (resync_req_i) begin
            unique case (output_state);
                StOutputNothing: begin
                    if (soon_next_frame) begin
                        if (new_frame_available) begin
                            output_state_next = StOutputData;
                            read_frame_next = last_good_frame_idx_i;
                            missed_frames_next = '0;
                        end else begin
                            output_state_next = StOutputZeros;
                        end
                    end
                end
                StOutputZeros: begin
                    if (soon_next_frame) begin
                        if (new_frame_available) begin
                            output_state_next = StOutputData;
                            read_frame_next = last_good_frame_idx_i;
                            missed_frames_next = '0;
                        end
                    end
                end
                StOutputData: begin
                    if (soon_next_frame) begin
                        if (new_frame_available) begin
                            read_frame_next = read_frame_r + 1'b1;
                            missed_frames_next = '0;
                        end else begin
                            missed_frames_next = missed_frames_r + 1'b1;
                            output_state_next = (missed_frames_r >= 3'd4) ? StOutputZeros : StOutputData;
                        end
                    end
                end
            endcase
        end else begin
            output_state_next = StOutputNothing;
        end
    end

    always_ff @(posedge clk_x4_i) begin
        if (!clk_main_tick_nr) begin
            read_frame_r <= read_frame_next;
            read_addr_lo_r <= read_addr_lo_next;
            output_state = output_state_next;
        end
    end

    wire no_output = output_state == StOutputNothing;

    assign ram_read_addr_o[CIRC_BUF_BITS-1+8:8] = read_frame_next;
    assign ram_read_addr_o[7:0] = read_addr_lo_next;
    assign i2s_running_o = !no_output;
    assign i2s_bclk_o = no_output ? 1'b0 : !clk_counter_r[0];
    assign i2s_lrclk_o = no_output ? 1'b0 : read_addr_lo_r[5]; // changes every 32 bits

    always_comb begin
        unique case (output_state);
            StOutputNothing: i2s_data_ro = 1'b0;
            StOutputZeros: i2s_data_ro = 1'b0;
            StOutputData: i2s_data_ro = ram_data_i;
            default: i2s_data_ro = 1'b0;
        endcase
    end
endmodule
