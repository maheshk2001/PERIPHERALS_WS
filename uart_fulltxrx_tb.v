`timescale 1ns/1ps

module uart_retransmission_tb;
    // Parameters
    parameter CLK_PERIOD = 10;     // 10ns clock period (100MHz)
    parameter size = 32;
    parameter TOTAL_BITS = 34;     // Including start, parity and stop bits

    // Testbench signals
    reg CLK_Baudin;
    reg RstTx, RstRx;
    reg NewData;
    reg [size-1:0] DataIn;
    wire [size-1:0] DataOut;
    wire TxSerial;
    wire DoneTx, DoneRx;
    reg Flag_tb;              // Flag to request retransmission
    reg loop;                 // Control single flag raise per transmission
    reg [5:0] bit_count;
    reg receiving;
    reg [31:0] received_data;

    // Instantiate UART top module
    uart_top dut (
        .CLK_Baudin(CLK_Baudin),
        .RstTx(RstTx),
        .RstRx(RstRx),
        .NewData(NewData),
        .DataIn(DataIn),
        .DataOut(DataOut),
        .DoneTx(DoneTx),
        .DoneRx(DoneRx),
        .TxSerial(TxSerial),
        .flag(Flag_tb)
    );

    // Clock Generation
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
            Flag_tb <= 0;
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
        Flag_tb = 0;
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
  if (TxSerial == 0 && receiving == 0) begin
        // Detect start bit
        receiving <= 1;
        bit_count <= 0;
        received_data <= 0;
    end else if (receiving) begin
        if (bit_count < 32) begin
          received_data <= {TxSerial, received_data[31:1]};
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
            if (TxSerial == 0 && !receiving) begin
                // Start bit detected
                receiving <= 1;
                bit_count <= 0;
                Flag_tb <= 0;
            end
            else if (receiving) begin
                if (bit_count < TOTAL_BITS) begin
                    if (bit_count == 32 && !loop) begin
                        Flag_tb <= 1;  // Raise flag at parity bit
                        loop <= 1;
                        $display("[TB] Raising Flag_Rx at bit_count=%0d, time=%0t", bit_count, $time);
                    end else begin
                        Flag_tb <= 0;
                    end
                    bit_count <= bit_count + 1;
                end else begin
                    receiving <= 0;
                    bit_count <= 0;
                    Flag_tb <= 0;
                end
            end
        end
    end

    // Monitor signals
    initial begin
        $monitor("Time=%0t RstTx=%b NewData=%b Flag_Rx=%b DoneTx=%b DoneRx=%b DataOut=%h bit_count=%d",
                 $time, RstTx, NewData, Flag_tb, DoneTx, DoneRx, DataOut, bit_count);
    end

    // Additional debug displays
    always @(posedge CLK_Baudin) begin
        if (DoneTx)
            $display("[TB] TX Done at time %0t", $time);
        if (DoneRx)
            $display("[TB] RX Done, DataOut=%h at time %0t", DataOut, $time);
      if (Flag_tb)
            $display("[TB] Flag raised for retransmission at bit_count=%0d, time=%0t", bit_count, $time);
    end

endmodule 
