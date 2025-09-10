module i2s_msb_receiver #(
    parameter CIRC_BUF_BITS=3
) (
    input                           clk_x4_i,
    input                           i2s_running_i,
    input                           i2s_data_i,

    output [CIRC_BUF_BITS-1+8:0]    ram_write_addr_o,
    output                          ram_write_en_o,
    output                          ram_write_data_o,
    output [CIRC_BUF_BITS-1:0]      last_good_frame_idx_o
);
    var bit [CIRC_BUF_BITS-1:0] write_frame_r = '0;
    logic [CIRC_BUF_BITS-1:0] write_frame_next;

    var bit [7:0] write_addr_lo_r = '0;
    logic [7:0] write_addr_lo_next;
    
    var bit [CIRC_BUF_BITS-1:0] last_good_frame_idx_r;
    logic [CIRC_BUF_BITS-1:0] last_good_frame_idx_next;

    var bit ram_write_en_r = '0;
    logic ram_write_en_next;

    var bit i2s_data_q = '0;

    wire soon_next_frame = (write_addr_lo_r == 8'hff);

    // Clock divider
    var bit [1:0] clk_counter_r;
    wire clk_main_tick_next = clk_counter_r[1] | clk_counter_r[0];
    var bit clk_main_tick_nr;

    always_ff @(posedge clk_x4_i) begin
        clk_counter_r <= clk_counter_r + 2'b1;
        clk_main_tick_nr <= clk_main_tick_next;
    end

    always_comb begin
        write_frame_next = write_frame_r;
        write_addr_lo_next = write_addr_lo_r + 8'b1;
        last_good_frame_idx_next = last_good_frame_idx_r;
        ram_write_en_next = i2s_running_i && (clk_counter_r == 2'b11);

        if (soon_next_frame) begin
            if (i2s_running_i) begin
                write_frame_next = write_frame_r + 1'd1;
                last_good_frame_idx_next = write_frame_r;
            end
        end
    end

    always_ff @(posedge clk_x4_i) begin
        // I2S MSB receiver samples data on rising edge of bclk
        if (clk_counter_r == 2'b11) begin
            i2s_data_q <= i2s_data_i;
        end

        ram_write_en_r <= ram_write_en_next;

        if (!clk_main_tick_nr) begin
            write_frame_r <= write_frame_next;
            write_addr_lo_r <= write_addr_lo_next;
            last_good_frame_idx_r <= last_good_frame_idx_next;
        end
    end

    assign ram_write_addr_o[CIRC_BUF_BITS-1+8:8] = write_frame_r;
    assign ram_write_addr_o[7:0] = write_addr_lo_r;
    assign ram_write_en_o = ram_write_en_r;
    assign ram_write_data_o = i2s_data_q;
    assign last_good_frame_idx_o = last_good_frame_idx_r;
endmodule
