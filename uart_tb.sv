//////////////////////////////////////////////////////////////////////
// File taken from http://www.nandland.com and Modified by Brandon Rivera
//////////////////////////////////////////////////////////////////////

`timescale 1ns/10ps

module uart_tb ();

    // Testbench uses a 25 MHz clock
    // Want to interface to 115200 baud UART
    // 25000000 / 115200 = 217 Clocks Per Bit.

    parameter CLOCK_PERIOD_NS = 40;
    parameter CYCLES_PER_BIT    = 217;
    parameter BIT_PERIOD      = 8600;
    
    logic clock = 0;
    logic txDataValid = 0;
    logic txActive, uartLine;
    logic txDataStream;
    logic [7:0] txByteData = 0;
    logic [7:0] rxByteData;
    logic rxDataValid;
    //logic done;


    uart_rx #(
        .CYCLES_PER_BIT(CYCLES_PER_BIT)
    ) uart_rx_inst (
        .clock,
        .rxDataStream(uartLine),
        .rxDataValid,
        .rxByteData
    );

    uart_tx #(
        .CYCLES_PER_BIT(CYCLES_PER_BIT)
    ) uart_tx_inst (
        .clock,
        .txDataValid,
        .txByteData,
        .txActive,
        .txDataStream,
        .done()
    );
    
    // Keeps the UART Receiver input high when
    // UART transmitter is not active
    assign uartLine = txActive ? txDataStream : 1'b1;
        
    always #(CLOCK_PERIOD_NS/2) clock <= !clock;
    
    // Main Testing:
    initial
        begin
        //Send byte through TX
        @(posedge clock);
        @(posedge clock);
        txDataValid   <= 1'b1;
        txByteData <= 8'h3F;
        @(posedge clock);
        txDataValid <= 1'b0;

        // Check byte through RX
        @(posedge rxDataValid);
        if (rxByteData == 8'h3F)
            $display("Test Passed - Correct Byte Received");
        else
            $display("Test Failed - Incorrect Byte Received");
        $finish();
        end
    
    initial 
    begin
        //OPtionally check signals using VaporView on VS Code
        $dumpfile("dump.vcd");
        $dumpvars(0);
    end
endmodule
