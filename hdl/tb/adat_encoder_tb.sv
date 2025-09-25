`include "../modules/adat_encoder.sv"
`include "../modules/channel_buffer.sv"
`include "../modules/nrzi_encoder.sv"

`timescale 10ns / 1ns
module adat_encoder_tb (
    output          clk_o,
    output          ram_data_o,
    output [3:0]    last_good_frame_idx_o,
    output [3:0]    user_bits_o,

    output [10:0]   ram_read_addr_o,
    output          adat_o
);
    var bit clk_state_r = '0;
    var bit [2:0] last_good_frame_idx_state_r = '0;
    var bit [3:0] user_bits_state_r = '0;

    assign clk_o = clk_state_r;
    assign last_good_frame_idx_o = last_good_frame_idx_state_r;
    assign user_bits_o = user_bits_state_r;

    wire [3:0] user_bits_rev;
    assign user_bits_rev[3] = user_bits_state_r[0];
    assign user_bits_rev[2] = user_bits_state_r[1];
    assign user_bits_rev[1] = user_bits_state_r[2];
    assign user_bits_rev[0] = user_bits_state_r[3];

    channel_buffer u_channel_buffer (
        .write_data_i               (1'b0),
        .read_addr_i                (ram_read_addr_o),
        .write_addr_i               ('0),
        .wr_en_i                    (1'b0),
        .clk_i                      (clk_state_r),
        .read_data_o                (ram_data_o)
    );

    adat_encoder #(
        .CIRC_BUF_BITS              (3)
    ) u_adat_encoder (
        .clk_i                      (clk_state_r),
        .ram_data_i                 (ram_data_o),
        .last_good_frame_idx_i      (last_good_frame_idx_state_r),
        .user_bits_i                (user_bits_rev),
        .ram_read_addr_o            (ram_read_addr_o),
        .adat_o                     (adat_o)
    );

    bit [10:0] out_write_idx = 'd0;
    bit [2047:0] nrzi_out = '0;

    // System clock process
    initial begin
        forever begin
            clk_state_r = '1;
            #4;

            nrzi_out[out_write_idx] = adat_o;
            out_write_idx = out_write_idx - 11'd1;

            clk_state_r = '0;
            #4;
        end
    end

    // Load data process
    int fd, status;
    var bit [2047:0] i2s_out;
    var bit [2047:0] nrzi_in;

    initial begin
        fd = $fopen("../../tb/adat_test_data_i2s.bin", "rb");
        status = $fread(i2s_out, fd);
        $fclose(fd);

        
        fd = $fopen("../../tb/adat_test_data_adat_nrzi.bin", "rb");
        status = $fread(nrzi_in, fd);
        $fclose(fd);

        for (int i = 0; i < 2048; i++) begin
            u_channel_buffer.u_simple_dual_port_ram_single_clock.ram[i] = i2s_out[2047 - i];
        end
    end

    // Main process
    var bit ok = '0;
    initial begin
        #50;

        for (int i = 1; i < 8; i++) begin
            last_good_frame_idx_state_r = i;
            user_bits_state_r = 4'd15 - i + 4'd1;
            #(8 * 256);
        end

        #2002;

        // Set first frame to zeros
        nrzi_in[2047:1792] = '0;
        nrzi_out[2047:1792] = '0;
        if (nrzi_in == nrzi_out) begin
            ok = '1;
        end else begin
            nrzi_in[2047:1792] = '1;
            nrzi_in = ~nrzi_in;

            if (nrzi_in == nrzi_out) begin
                ok = '1;
            end
        end

        if (ok) begin
            $display("Data transmitted correctly, yay!");
        end else begin
            $display("Something is wrong...");
            $display("Input data: %b", nrzi_in);
            $display("Captured output data: %b", nrzi_out);
        end

        #20000;

        $stop;
    end
endmodule
