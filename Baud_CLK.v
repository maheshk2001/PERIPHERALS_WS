// Clock Divider // 20ns div 217.
module Baud_CLK(clk, rst, div_val, clk_out);
    parameter WIDTH = 32;
    input wire clk;
    input wire rst;
    input wire [WIDTH-1:0] div_val;
    output reg clk_out;
    reg [WIDTH-1:0] counter;

    always @(posedge clk) begin
        if (rst) begin
            counter <= 0;
            clk_out <= 0;
        end else begin
            if (div_val > 1) begin
                if (counter == div_val - 1) begin
                    counter <= 0;
                    clk_out <= ~clk_out;
                end else begin
                    counter <= counter + 1;
                end
            end else begin
                clk_out <= clk;
            end
        end
    end
endmodule