module i2s_msb_receiver #(
    parameter CIRC_BUF_BITS=3
) (
    input                           clk_i,
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

    always_comb begin
        write_frame_next = write_frame_r;
        write_addr_lo_next = write_addr_lo_r + 8'b1;
        last_good_frame_idx_next = last_good_frame_idx_r;
        ram_write_en_next = i2s_running_i;

        if (soon_next_frame) begin
            if (i2s_running_i) begin
                write_frame_next = write_frame_r + 1'd1;
                last_good_frame_idx_next = write_frame_r;
            end
        end
    end

    // Sample using bclk to avoid setup/hold violations
    // BCLK is driven by us (our systemclk), so we shouldn't have any timing
    // issues
    always_ff @(negedge clk_i) begin
        i2s_data_q <= i2s_data_i;
    end

    always_ff @(posedge clk_i) begin
        ram_write_en_r <= ram_write_en_next;
        write_frame_r <= write_frame_next;
        write_addr_lo_r <= write_addr_lo_next;
        last_good_frame_idx_r <= last_good_frame_idx_next;
    end

    assign ram_write_addr_o[CIRC_BUF_BITS-1+8:8] = write_frame_r;
    assign ram_write_addr_o[7:0] = write_addr_lo_r;
    assign ram_write_en_o = ram_write_en_next;
    assign ram_write_data_o = i2s_data_q;
    assign last_good_frame_idx_o = last_good_frame_idx_r;
endmodule
