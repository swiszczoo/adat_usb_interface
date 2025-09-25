// This module synchronizes to ADAT input stream and outputs 
// interleaved 32-bit 8-channel bitstream to a M9K RAM circular buffer
module adat_decoder #(
    parameter CIRC_BUF_BITS=3
) (
    input                                   clk_i,
    input                                   clk_x4_i,
    input                                   nrzi_i,
    input                                   reset_i,

    output                                  ram_write_en_o,
    output [CIRC_BUF_BITS-1+8:0]            ram_write_addr_o,
    output                                  ram_write_data_o,
    output [CIRC_BUF_BITS-1:0]              last_good_frame_idx_o,
    output [3:0]                            user_bits_o,
    output                                  has_sync_o,
    output                                  raw_adat_o,
    output                                  raw_adat_valid_o
);
    typedef enum bit[2:0] {
        // Initial state
        StIdle,

        // We are currently waiting for the NRZI decoder module to sync to the incoming bitstream
        StWaitForNrziSync,

        // We are currently waiting for ADAT sync pattern (10 consecutive zeros)
        StWaitForAdatSync,

        // We are currently decoding user bits
        StDecodingUser,

        // We are currently decoding sample data
        StDecodingSamples,

        // We are currently committing current frame
        StCommit,

        // A decoding error occured
        StError
    } decoder_state_e;

    wire adat_bit;
    wire adat_valid;
    wire adat_sync;
    var bit adat_sync_q = '0, adat_sync_q2 = '0;

    wire adat_sync_now = adat_sync && adat_sync_q && adat_sync_q2;

    nrzi_phase_lock_decoder u_nrzi_phase_lock_decoder (
        .clk_i                  (clk_i),
        .clk_x4_i               (clk_x4_i),
        .nrzi_i                 (nrzi_i),
        .data_o                 (adat_bit),
        .valid_o                (adat_valid),

        // starts outputting 1 after 8 consecutive zeroes
        // can be used for ADAT frame synchronization
        .sync_o                 (adat_sync)
    );

    assign raw_adat_o = adat_bit;
    assign raw_adat_valid_o = adat_valid;

    decoder_state_e decoder_state = StIdle;
    decoder_state_e decoder_state_next;

    var bit has_sync_r = '0;
    logic has_sync_next;

    var bit [3:0] user_bits_qr = '0;
    logic [3:0] user_bits_q_next;

    var bit [3:0] user_bits_r = '0;
    logic [3:0] user_bits_next;

    var bit [2:0] nibble_counter_r = '0;
    logic [2:0] nibble_counter_next;

    var bit [CIRC_BUF_BITS-1:0] last_good_frame_idx_r = '0;
    logic [CIRC_BUF_BITS-1:0] last_good_frame_idx_next;

    var bit [CIRC_BUF_BITS-1:0] addr_hi_r = '0;
    logic [CIRC_BUF_BITS-1:0] addr_hi_next;

    var bit [2:0] addr_mi_q = '0;
    var bit [2:0] addr_mi_r = '0;
    logic [2:0] addr_mi_next;

    var bit [4:0] addr_lo_q = '0;
    var bit [4:0] addr_lo_r = '0;
    logic [4:0] addr_lo_next;

    var write_en_r = '0;
    logic write_en_next;

    var write_data_r = '0;
    logic write_data_next;

    // This equals one if this is the first bit in 5-bit nibble (which must be equal to 1)
    wire first_in_nibble = nibble_counter_r == 'd0;

    // This equals zero only if the first bit of a fifth is not a one
    wire valid_adat_bit = !(nibble_counter_r == 'd0 && !adat_bit) && adat_valid;

    // This equals one if this is the fifth bit of a single nibble
    wire full_nibble = nibble_counter_r >= 'd4;

    wire last_channel = addr_mi_r == 'd7;
    wire last_sample = addr_lo_r == 'd23;

    always_comb begin
        has_sync_next = has_sync_r;
        user_bits_next = '0;
        user_bits_q_next = user_bits_qr;
        nibble_counter_next = nibble_counter_r;
        last_good_frame_idx_next = last_good_frame_idx_r;
        addr_hi_next = addr_hi_r;
        addr_mi_next = addr_mi_r;
        addr_lo_next = addr_lo_r;
        write_en_next = '0;
        write_data_next = '0;

        if (reset_i) begin
            decoder_state_next = StIdle;
        end else begin
            unique case (decoder_state)
                StIdle: begin
                    decoder_state_next = StWaitForNrziSync;
                    has_sync_next = '0;
                end // StIdle
                StWaitForNrziSync: begin
                    decoder_state_next = adat_valid ? StWaitForAdatSync : StWaitForNrziSync;
                    has_sync_next = '0;
                end // StWaitForNrziSync
                StWaitForAdatSync: begin
                    nibble_counter_next = '0;
                    if (!adat_valid) decoder_state_next = StWaitForNrziSync;
                    else decoder_state_next = adat_sync_now ? StDecodingUser : StWaitForAdatSync;
                end // StWaitForAdatSync
                StDecodingUser: begin
                    user_bits_next[2:0] = user_bits_r[3:1];
                    user_bits_next[3] = adat_bit;
                    addr_mi_next = '0;
                    addr_lo_next = '0;
                    nibble_counter_next = full_nibble ? 3'd0 : nibble_counter_r + 3'd1;

                    if (!valid_adat_bit) begin
                        decoder_state_next = StError;
                    end else begin
                        decoder_state_next = full_nibble ? StDecodingSamples : StDecodingUser;
                    end
                end // StDecodingUser
                StDecodingSamples: begin
                    user_bits_next = user_bits_r;
                    nibble_counter_next = full_nibble ? 3'd0 : nibble_counter_r + 3'd1;

                    if (first_in_nibble) begin
                        decoder_state_next = valid_adat_bit ? StDecodingSamples : StError;
                    end else begin
                        if (last_channel && last_sample) begin
                            decoder_state_next = StCommit;
                        end else begin
                            decoder_state_next = valid_adat_bit ? StDecodingSamples : StError;
                        end

                        addr_mi_next = last_sample ? (addr_mi_r + 3'd1) : (addr_mi_r);
                        addr_lo_next = last_sample ? 5'd0 : (addr_lo_r + 5'd1);

                        write_en_next = 'b1;
                        write_data_next = adat_bit;
                    end
                end // StDecodingSamples
                StCommit: begin
                    decoder_state_next = StWaitForAdatSync;
                    addr_hi_next = addr_hi_r + 1'd1;
                    last_good_frame_idx_next = addr_hi_r;
                    user_bits_q_next = user_bits_r;
                    has_sync_next = '1;
                end // StCommit
                default: begin
                    decoder_state_next = StIdle;
                    has_sync_next = '0;
                end
            endcase
        end
    end

    always_ff @(posedge clk_i) begin
        adat_sync_q <= adat_sync;
        adat_sync_q2 <= adat_sync_q;

        decoder_state <= decoder_state_next;

        has_sync_r <= has_sync_next;
        user_bits_qr <= user_bits_q_next;
        user_bits_r <= user_bits_next;
        nibble_counter_r <= nibble_counter_next;
        last_good_frame_idx_r <= last_good_frame_idx_next;
        addr_hi_r <= addr_hi_next;
        addr_mi_r <= addr_mi_next;
        addr_lo_r <= addr_lo_next;
        addr_mi_q <= addr_mi_r;
        addr_lo_q <= addr_lo_r;
        write_en_r <= write_en_next;
        write_data_r <= write_data_next;
    end

    assign ram_write_en_o = write_en_r;
    assign ram_write_addr_o[CIRC_BUF_BITS - 1 + 8:8] = addr_hi_r;
    assign ram_write_addr_o[7:5] = addr_mi_q;
    assign ram_write_addr_o[4:0] = addr_lo_q;
    assign ram_write_data_o = write_data_r;
    assign last_good_frame_idx_o = last_good_frame_idx_r;
    assign user_bits_o = user_bits_qr;
    assign has_sync_o = has_sync_r;
endmodule
