`include "../ip/fifo_dual_clock.v"
`include "../modules/nrzi_phase_lock_decoder.sv"
`include "jitter_generator.sv"

`timescale 10ns / 1ns
module nrzi_phase_lock_decoder_tb(
    output reg      in_bit_o,
    output          nrzi_state_o,
    output          clk_o,
    output          clk_x4_o,
    output          data_o,
    output          valid_o,
    output          sync_o
);
    bit [559:0] data_tx_r;
    var bit [559:0] data_rx_r;
    var bit nrzi_state_r = '0;
    var bit clk_state_r = '0;
    var bit clk_state_x4_r = '0;
    var bit [15:0] write_pos_r = '0;
    const real jitter_amount = 2.0;

    wire logic output_data;
    wire logic output_valid;

    nrzi_phase_lock_decoder u_nrzi_phase_lock_decoder (
        .clk_i              (clk_state_r),
        .clk_x4_i           (clk_state_x4_r),
        .nrzi_i             (nrzi_state_r),
        .data_o             (data_o),
        .valid_o            (valid_o),
        .sync_o             (sync_o)
    );

    assign nrzi_state_o = nrzi_state_r;
    assign clk_o = clk_state_r;
    assign clk_x4_o = clk_state_x4_r;

    bit data_in;
    jitter_generator jitter_gen = new ();

    initial begin
        for (int i = 0; i < 512; i++) begin
            data_tx_r[i] = $urandom() % 2;
        end

        data_tx_r[0] = '1;
        in_bit_o = '0;

        jitter_gen.initialize ();
        for (int i = 0; i < 560; i++) begin
            data_in = data_tx_r[i];
            in_bit_o = data_in;
            if (data_in) begin
                nrzi_state_r = !nrzi_state_r;
            end

            jitter_gen.jitter(jitter_amount);
        end

        #128;

        $display("Input data: %b", data_tx_r);
        $display("Captured output data: %b", data_rx_r);

        // the first sync transition will be missing in the output
        // and we can give the module a bit of room to synchronize
        data_tx_r[3:0] = 4'b0000;

        repeat (64) begin
            data_rx_r = data_rx_r >> 1; 
            data_rx_r[3:0] = 4'b0000;

            if (data_rx_r == data_tx_r) begin
                $display("Data received correctly, yay!");
            end
        end

        $stop;
    end

    // x4 clock process
    initial begin
        forever begin
            clk_state_x4_r = '1;
            #1;
            clk_state_x4_r = '0;
            #1;
        end
    end

    // system clock process
    initial begin
        forever begin
            clk_state_r = '1;
            #4;
            clk_state_r = '0;
            #4;
            
            data_rx_r[write_pos_r] = data_o;
            write_pos_r = write_pos_r + 'd1;
        end
    end
endmodule
