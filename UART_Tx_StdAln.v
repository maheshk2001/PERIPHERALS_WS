`timescale 1ns/1ps

module UART_Tx_tb;

    reg CLK_Baudin;
    reg RstTx;
    reg NewData;
    reg Flag_in;
    reg [31:0] DataIn;
    wire TransmittedSerialData;
    wire DoneTx;

    // For reconstructing received data
    reg [31:0] received_data;
    reg [5:0] bit_count;
    reg receiving;

    // Instantiate your UART_Tx
    UART_Tx uut (
        .TransmittedSerialData(TransmittedSerialData),
        .DoneTx(DoneTx),
        .DataIn(DataIn),
        .CLK_Baudin(CLK_Baudin),
        .RstTx(RstTx),
        .NewData(NewData),
        .Flag_in(Flag_in)
    );

    // Clock Generation (Baud clock)
    initial begin
        CLK_Baudin = 0;
        forever #50 CLK_Baudin = ~CLK_Baudin; // 100ns clock period
    end

    // Test sequence
    initial begin
        $dumpfile("UART_Tx_tb.vcd");
        $dumpvars(0, UART_Tx_tb);

        // Initialize inputs
        RstTx = 1;
        NewData = 0;
        Flag_in = 0;
        DataIn = 32'h0;
        received_data = 32'h0;
        bit_count = 0;
        receiving = 0;

        #200;
        RstTx = 0; // Release reset

        #100;
        DataIn = 32'hA5A5F0F0; // Example 1
        start_transmission();

        wait (DoneTx == 1);
        check_result();

        #200;
        DataIn = 32'hDEADBEEF; // Example 2
        start_transmission();

        wait (DoneTx == 1);
        check_result();

        #500;
        $finish;
    end

    // Task to start transmission
    task start_transmission;
    begin
        NewData = 1;
        #100;
        NewData = 0;
        receiving = 0;
        received_data = 0;
        bit_count = 0;
    end
    endtask

    // Task to check result
    task check_result;
    begin
        if (received_data == DataIn)
            $display("✅ MATCH: Sent = %h, Received = %h at time %0t", DataIn, received_data, $time);
        else
            $display("❌ MISMATCH: Sent = %h, Received = %h at time %0t", DataIn, received_data, $time);
    end
    endtask

    // Receiving logic: reconstruct the transmitted data
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
            end else begin
                // After receiving data bits, ignore parity and stop bit
                receiving <= 0;
            end
        end
    end

    // Monitor transmission (optional for debug)
    always @(posedge CLK_Baudin) begin
        $display("Time %0t: Tx = %b, DoneTx = %b", $time, TransmittedSerialData, DoneTx);
    end

endmodule
