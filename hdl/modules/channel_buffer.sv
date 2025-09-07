// Quartus Prime Verilog Template
// Simple Dual Port RAM with separate read/write addresses and
// single read/write clock

module simple_dual_port_ram_single_clock
#(parameter DATA_WIDTH=8, parameter ADDR_WIDTH=6)
(
    input [(DATA_WIDTH-1):0] data,
    input [(ADDR_WIDTH-1):0] read_addr, write_addr,
    input we, clk,
    output reg [(DATA_WIDTH-1):0] q
);

    // Declare the RAM variable
    reg [DATA_WIDTH-1:0] ram[2**ADDR_WIDTH-1:0];

    // This should be synthesizable
    initial begin
        for (int i = 0; i < 2**ADDR_WIDTH; i++) begin
            ram[i] = '0;
        end
    end

    always @ (posedge clk) begin
        // Write
        if (we)
            ram[write_addr] <= data;

        // Read (if read_addr == write_addr, return OLD data).	To return
        // NEW data, use = (blocking write) rather than <= (non-blocking write)
        // in the write assignment.	 NOTE: NEW data may require extra bypass
        // logic around the RAM.
        q <= ram[read_addr];
    end

endmodule

// Circular buffer for one ADAT channel (8 audio channels)
module channel_buffer (
    input               write_data_i,
    input [10:0]        read_addr_i,
    input [10:0]        write_addr_i,
    input               wr_en_i,
    input               clk_i,
    output              read_data_o
);
    simple_dual_port_ram_single_clock #(
        .DATA_WIDTH    (1),         // We access single bit at once
        .ADDR_WIDTH    (8 + 3)      // 8 samples of data
    ) u_simple_dual_port_ram_single_clock (
        .data          (write_data_i),
        .read_addr     (read_addr_i),
        .write_addr    (write_addr_i),
        .we            (wr_en_i),
        .clk           (clk_i),
        .q             (read_data_o)
    );
endmodule
