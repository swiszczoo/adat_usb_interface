module adat_encoder #(
    parameter CIRC_BUF_BITS=3
) (
    input                           clk_i,
    input                           ram_data_i,
    input [CIRC_BUF_BITS-1:0]       last_good_frame_idx_i,
    input [3:0]                     user_bits_i,

    output [CIRC_BUF_BITS-1+8:0]    ram_read_addr_o,
    output                          adat_o
);
    typedef enum bit {
        StOutputZeros,
        StOutputData
    } transmitter_state_e;

    typedef enum bit [1:0] {
        StTransmitSamples,
        StTransmitSync,
        StTransmitUserBits
    } adat_part_e;

    var bit [CIRC_BUF_BITS-1:0] read_frame_r = '0;
    logic [CIRC_BUF_BITS-1:0] read_frame_next;

    var bit [2:0] read_addr_mi_r = '0;
    logic [2:0] read_addr_mi_next;

    var bit [4:0] read_addr_lo_r = '0;
    logic [4:0] read_addr_lo_next;

    var bit [2:0] missed_frames_r = '0;
    logic [2:0] missed_frames_next;

    var bit [3:0] nibble_counter_r = '0;
    logic [3:0] nibble_counter_next;

    var bit [3:0] user_bits_q = '0;
    logic [3:0] user_bits_q_next;

    transmitter_state_e transmitter_state = StOutputZeros;
    transmitter_state_e transmitter_state_next;

    adat_part_e adat_state = StTransmitSamples;
    adat_part_e adat_state_next;

    // This equals one if this is the first bit in 5-bit nibble (which must be equal to 1)
    wire first_in_nibble = nibble_counter_r == 'd0;

    // This equals one if this is the fifth bit of a single nibble
    wire full_nibble = nibble_counter_r[2];

    // This equals one if this is the last zero of the sync pattern
    wire full_sync = nibble_counter_r == 4'd10;

    wire last_channel = read_addr_mi_r == 3'd7;
    wire last_sample = read_addr_lo_r == 5'd23;
    wire soon_next_frame = (adat_state == StTransmitUserBits && nibble_counter_r == 4'd4);
    wire new_frame_available = (last_good_frame_idx_i != read_frame_r);

    always_comb begin
        transmitter_state_next = transmitter_state;
        read_frame_next = read_frame_r;
        missed_frames_next = missed_frames_r;

        unique case (transmitter_state)
            StOutputZeros: begin
                if (soon_next_frame) begin
                    if (new_frame_available) begin
                        transmitter_state_next = StOutputData;
                        read_frame_next = last_good_frame_idx_i;
                        missed_frames_next = '0;
                    end
                end
            end // StOutputZeros
            StOutputData: begin
                if (soon_next_frame) begin
                    if (new_frame_available) begin
                        read_frame_next = last_good_frame_idx_i;
                        missed_frames_next = '0;
                    end else begin
                        missed_frames_next = missed_frames_r + 1'b1;
                        transmitter_state_next = (missed_frames_r >= 3'd4) ? StOutputZeros : StOutputData;
                    end
                end
            end // StOutputData
            default: transmitter_state_next = StOutputZeros;
        endcase
    end

    logic actual_data;
    always_comb begin
        unique case (transmitter_state)
            StOutputZeros: actual_data = '0;
            StOutputData: actual_data = ram_data_i;
            default: actual_data = '0;
        endcase
    end

    logic adat_bit;
    always_comb begin
        adat_state_next = adat_state;
        read_addr_mi_next = read_addr_mi_r;
        read_addr_lo_next = read_addr_lo_r;
        user_bits_q_next = user_bits_q;

        unique case (adat_state)
            StTransmitSamples: begin
                nibble_counter_next = full_nibble ? '0 : nibble_counter_r + 4'd1;

                if (first_in_nibble) begin
                    // every nibble starts with an additional 1 for NRZI synchronization
                    adat_bit = '1;
                end else begin
                    if (last_channel && last_sample) begin
                        adat_state_next = StTransmitSync;
                    end

                    read_addr_mi_next = last_sample ? (read_addr_mi_r + 'd1) : (read_addr_mi_r);
                    read_addr_lo_next = last_sample ? '0 : (read_addr_lo_r + 'd1);

                    adat_bit = actual_data;
                end
            end // StTransmitSamples
            StTransmitSync: begin
                nibble_counter_next = full_sync ? '0 : nibble_counter_r + 4'd1;
                adat_state_next = full_sync ? StTransmitUserBits : StTransmitSync;
                adat_bit = first_in_nibble ? '1 : '0;

                user_bits_q_next = full_sync ? user_bits_i : user_bits_q;
            end // StTransmitSync
            StTransmitUserBits: begin
                nibble_counter_next = full_nibble ? '0 : nibble_counter_r + 4'd1;
                adat_state_next = full_nibble ? StTransmitSamples : StTransmitUserBits;

                if (first_in_nibble) begin
                    // every nibble starts with an additional 1 for NRZI synchronization
                    adat_bit = '1;
                end else begin
                    adat_bit = user_bits_q[0];
                    user_bits_q_next[3] = '0;
                    user_bits_q_next[2:0] = user_bits_q[3:1];
                end
            end
            default: adat_state_next = StTransmitSamples;
        endcase
    end

    always_ff @(posedge clk_i) begin
        read_frame_r <= read_frame_next;
        read_addr_mi_r <= read_addr_mi_next;
        read_addr_lo_r <= read_addr_lo_next;
        missed_frames_r <= missed_frames_next;
        nibble_counter_r <= nibble_counter_next;
        user_bits_q <= user_bits_q_next;

        transmitter_state <= transmitter_state_next;
        adat_state <= adat_state_next;
    end

    nrzi_encoder u_nrzi_encoder (
        .clk_i                  (clk_i),
        .data_i                 (adat_bit),
        .output_en_i            (1'b1),
        .data_o                 (adat_o)
    );

    assign ram_read_addr_o[CIRC_BUF_BITS - 1 + 8:8] = read_frame_next;
    assign ram_read_addr_o[7:5] = read_addr_mi_next;
    assign ram_read_addr_o[4:0] = read_addr_lo_next;
endmodule
