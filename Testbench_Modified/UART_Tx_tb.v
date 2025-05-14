
`timescale 1ns/1ps

module UART_tb;

    // Clock and Reset signals
     parameter CLK_PERIOD = 10;     // 10ns clock period (100MHz)
    parameter size = 32;
    parameter TOTAL_BITS = 34;
    reg CLK_Baudin;
    reg Rst;
    reg RstTx,RstRx;

    // Transmitter signals
    reg [31:0] DataIn;
    reg NewData;
    wire TransmittedSerialData;
    wire DoneTx;
    //wire Flag_in;

    // Receiver signals
    wire [31:0] DataOut;
    wire DoneRx;
    //reg Flag_Rx;

    // For reconstructing received data
    reg [31:0] received_data;
    reg [5:0] bit_count;
    reg receiving;
    reg loop;

    // Instantiate UART Transmitter
    UART_Tx uut_tx (
        .TransmittedSerialData(TransmittedSerialData),
        .DoneTx(DoneTx),
        .DataIn(DataIn),
        .CLK_Baudin(CLK_Baudin),
        .RstTx(Rst),
        .NewData(NewData),
      .Flag_in(Flag_in)
    );

    // Instantiate UART Receiver
    UART_Rx uut_rx (
        .DataOut(DataOut),
        .DoneRx(DoneRx),
        .SerialInputData(TransmittedSerialData),
        .CLK_Baudin(CLK_Baudin),
        .RstRx(Rst),
        .Flag_Rx(Flag_Rx)
    );
     // Connect Flag_Rx to Flag_in
    //assign Flag_in = Flag_Rx;

   initial begin
        CLK_Baudin = 0;
        forever #(CLK_PERIOD/2) CLK_Baudin = ~CLK_Baudin;
    end

    // Task to start transmission
    task start_transmission;
        input [size-1:0] data;
        begin
            $display("[TB] Starting transmission of data: %h at time %0t", data, $time);
            DataIn = data;
            NewData = 1;
            #10;
            NewData = 0;
            receiving = 0;
            bit_count = 0;
            loop = 0;
            Flag_Rx <= 0;
        end
    endtask

    // Test sequence
    initial begin
        // Initialize
      
        $dumpfile("uart_retransmission_tb.vcd");
        $dumpvars(0, uart_retransmission_tb);
        RstTx = 1;
        RstRx = 1;
        NewData = 0;
        DataIn = 32'h0;
        bit_count = 0;
        receiving = 0;
        Flag_Rx <= 0;
        loop = 0;

        // Reset sequence
        #200;
        RstTx = 0;
        RstRx = 0;
        #100;

        // Test Case 1: Normal transmission
        start_transmission(32'hA5A5A5A5);
        wait(DoneTx);
        #100;

        // Test Case 2: Transmission with flag raising
        start_transmission(32'hDEADBEEF);
        wait(DoneTx);
        #100;

        // Test Case 3: Another transmission
        start_transmission(32'h12345678);
        wait(DoneTx);
        #100;

        // End simulation
        #1000;
        $finish;
    end


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
    // Bit counter and flag control
    always @(posedge CLK_Baudin) begin
        if (!RstTx && !RstRx) begin
          if (TransmittedSerialData == 0 && !receiving) begin
                // Start bit detected
                receiving <= 1;
                bit_count <= 0;
                Flag_Rx <= 0;
            end
            else if (receiving) begin
                if (bit_count < TOTAL_BITS) begin
                    if (bit_count == 32 && !loop) begin
                        Flag_Rx <= 1;  // Raise flag at parity bit
                        loop <= 1;
                        $display("[TB] Raising Flag_Rx at bit_count=%0d, time=%0t", bit_count, $time);
                    end else begin
                        Flag_Rx <= 0;
                    end
                    bit_count <= bit_count + 1;
                end else begin
                    receiving <= 0;
                    bit_count <= 0;
                    Flag_Rx <= 0;
                end
            end
        end
    end

    // Monitor signals
    initial begin
        $monitor("Time=%0t RstTx=%b NewData=%b Flag_Rx=%b DoneTx=%b DoneRx=%b DataOut=%h bit_count=%d",
                 $time, RstTx, NewData, Flag_Rx, DoneTx, DoneRx, DataOut, bit_count);
    end

    // Additional debug displays
    always @(posedge CLK_Baudin) begin
        if (DoneTx)
            $display("[TB] TX Done at time %0t", $time);
        if (DoneRx)
            $display("[TB] RX Done, DataOut=%h at time %0t", DataOut, $time);
        if (Flag_Rx)
            $display("[TB] Flag raised for retransmission at bit_count=%0d, time=%0t", bit_count, $time);
    end

endmodule 
