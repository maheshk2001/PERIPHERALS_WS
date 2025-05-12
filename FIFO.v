module FIFO (
    input wire clk,
    input wire rst_n,           // Active-low synchronous reset
    input wire wr_en,           // Write enable
    input wire rd_en,           // Read enable
    input wire [31:0] din,      // Data input
    output reg [31:0] dout,     // Data output
    output reg full,            // FIFO full flag
    output reg empty            // FIFO empty flag
);

    parameter DEPTH = 16;
    parameter ADDR_WIDTH = 4;   // log2(16) = 4

    reg [31:0] mem [0:DEPTH-1]; // 16-depth memory of 32-bit width
    reg [ADDR_WIDTH-1:0] wr_ptr;
    reg [ADDR_WIDTH-1:0] rd_ptr;
    reg [ADDR_WIDTH:0] count;   // 5-bit count to track number of elements

    // Write Operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 0;
        end else if (wr_en && !full) begin
            mem[wr_ptr] <= din;
            wr_ptr <= wr_ptr + 1;
        end
    end

    // Read Operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr <= 0;
            dout <= 0;
        end else if (rd_en && !empty) begin
            dout <= mem[rd_ptr];
            rd_ptr <= rd_ptr + 1;
        end
    end

    // Count Logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 0;
        end else begin
            case ({wr_en && !full, rd_en && !empty})
                2'b10: count <= count + 1; // Write only
                2'b01: count <= count - 1; // Read only
                default: count <= count;   // No change or simultaneous read/write
            endcase
        end
    end

    // Status Flags
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            full <= 0;
            empty <= 1;
        end else begin
            full <= (count == DEPTH);
            empty <= (count == 0);
        end
    end

endmodule
