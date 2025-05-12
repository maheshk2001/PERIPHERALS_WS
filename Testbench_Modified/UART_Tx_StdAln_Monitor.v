`timescale 1ns/1ps

module UART_Tx_StdAln_Monitor(    input reg TransmittedSerialData,
    input reg DoneTx,
    input reg [31:0]DataIn,
    input reg CLK_Baudin,
    input reg RstTx,
    input reg NewData,
    input reg Flag_in,
    output reg receiving
); 
// For reconstructing received data
reg [31:0] received_data;
reg [5:0] bit_count;

    
initial begin
$dumpfile("/home/mahesk/arails/ts40peripherals24a/ts40_p240_1P10M_7X0Y2Z0R0U_0p9_1p5/PERIPHERALS_WS/UART_Tx_tb.vcd");
    $dumpvars(0, UART_Tx_tb);
    bit_count = 0;
received_data = 32'h0;
receiving = 0;
    end

localparam TOTAL_BITS = 34;
always @(posedge CLK_Baudin) begin
    if (TransmittedSerialData == 0 && receiving == 0) begin
        // Detect start bit
        receiving <= 1;
        bit_count <= 0;
        received_data <= 0;
    end else if (receiving) begin
        if (bit_count < 32) begin
            received_data <= {TransmittedSerialData, received_data[31:1]};
            bit_count <= bit_count + 1;
        end else if (bit_count < TOTAL_BITS) begin
            // Counting parity and stop bits
            bit_count <= bit_count + 1;
        end else begin
            // Done receiving entire frame
            receiving <= 0;
            bit_count <= 0;
        end
    end
end


// Monitor to display expected input and received output
always @(posedge CLK_Baudin) begin
    if (bit_count == TOTAL_BITS - 1 && receiving) begin
        $display("----------------------------------------------------");
        $display("Time %0t:", $time);
        $display("Expected Output (DataIn):       0x%h", DataIn);
        $display("Reconstructed Output (RX):     0x%h", received_data);
        if (DataIn == received_data)
            $display("Match: Received data matches input.");
        else
            $display("Mismatch: Received data does NOT match input.");
    end
end

endmodule

