`include "../modules/channel_buffer.sv"
`include "../modules/i2s_msb_receiver.sv"
`include "../modules/i2s_msb_transmitter.sv"

`timescale 10ns / 1ns
module i2s_loopback_tb (
    output                      clk_o,
    output                      ram_data_o,
    output                      resync_req_o,
    output [ 2:0]               last_good_frame_idx_o,
    output [10:0]               ram_read_addr_o,
    output                      i2s_running_o,
    output                      i2s_bclk_o,
    output                      i2s_lrclk_o,
    output reg                  i2s_data_ro,
    output [10:0]               ram_write_addr_o,
    output                      ram_write_en_o,
    output                      ram_write_data_o,
    output [ 2:0]               last_good_frame_idx_dest_o
);
    var bit clk_state_r = '0;
    var bit resync_req_state_r = '0;
    var bit [2:0] last_good_frame_idx_state_r = '0;

    assign clk_o = clk_state_r;
    assign resync_req_o = resync_req_state_r;
    assign last_good_frame_idx_o = last_good_frame_idx_state_r;

    channel_buffer u_buffer_source (
        .write_data_i               (1'b0),
        .read_addr_i                (ram_read_addr_o),
        .write_addr_i               ('0),
        .wr_en_i                    (1'b0),
        .clk_i                      (clk_state_r),
        .read_data_o                (ram_data_o)
    );

    i2s_msb_transmitter #(
        .CIRC_BUF_BITS              (3)
    ) u_i2s_msb_transmitter (
        .clk_i                      (clk_state_r),
        .ram_data_i                 (ram_data_o),
        .resync_req_i               (resync_req_state_r),
        .last_good_frame_idx_i      (last_good_frame_idx_state_r),
        .ram_read_addr_o            (ram_read_addr_o),
        .i2s_running_o              (i2s_running_o),
        .i2s_bclk_o                 (i2s_bclk_o),
        .i2s_lrclk_o                (i2s_lrclk_o),
        .i2s_data_ro                (i2s_data_ro)
    );

    i2s_msb_receiver #(
        .CIRC_BUF_BITS              (3)
    ) u_i2s_msb_receiver (
        .clk_i                      (clk_state_r),
        .i2s_running_i              (i2s_running_o),
        .i2s_data_i                 (i2s_data_ro),
        .i2s_bclk_i                 (i2s_bclk_o),
        .ram_write_addr_o           (ram_write_addr_o),
        .ram_write_en_o             (ram_write_en_o),
        .ram_write_data_o           (ram_write_data_o),
        .last_good_frame_idx_o      (last_good_frame_idx_dest_o)
    );

    channel_buffer u_buffer_dest (
        .write_data_i               (ram_write_data_o),
        .read_addr_i                (11'b0),
        .write_addr_i               (ram_write_addr_o),
        .wr_en_i                    (ram_write_en_o),
        .clk_i                      (clk_state_r),
        .read_data_o                ()
    );

    // Clock process
    initial begin
        forever begin
            clk_state_r = '1;
            #4;
            clk_state_r = '0;
            #4;
        end
    end

    // Fill source and dest buffer process
    initial begin
        for (int i = 0; i < 2048; i++) begin
            u_buffer_source.u_simple_dual_port_ram_single_clock.ram[i] = $urandom % 2;
            u_buffer_dest.u_simple_dual_port_ram_single_clock.ram[i] = 1'b0;
        end
    end

    // Main process
    bit valid = '1;
    initial begin
        #50;

        resync_req_state_r = 1'b1;
        last_good_frame_idx_state_r = 1'b1;

        for (int i = 2; i < 8; i++) begin
            #(8 * 256);
            last_good_frame_idx_state_r = i;
        end

        #(8 * 256);
        last_good_frame_idx_state_r = 0;
        #(8 * 256);

        while (ram_read_addr_o != 11'h0ff) #1;
        #7;

        resync_req_state_r = 1'b0;

        #9;

        for (int i = 0; i < 2048; i++) begin
            if (u_buffer_source.u_simple_dual_port_ram_single_clock.ram[(i + 256) % 2048]
                != u_buffer_dest.u_simple_dual_port_ram_single_clock.ram[i]) begin
                
                valid = '0;
                $display("Error at bit: %d", i);
            end
        end

        if (valid) begin
            $display("Everything is ok!");
        end else begin
            $display("Something is wrong!");
        end

        $stop;
    end
endmodule
