`timescale 1ns/1ps

module uart_tb;
    parameter CYCLES_PER_BIT = 217;
    parameter CLK_PERIOD = 10;

    logic clock;
    logic txDataValid;
    logic [7:0] txByteData;
    logic txActive;
    logic serialDataStream;
    logic done;

    logic rxDataValid;
    logic [7:0] rxByteData;

    uart_tx #(
        .CYCLES_PER_BIT(CYCLES_PER_BIT)
    ) tx_inst (
        .clock(clock),
        .txDataValid(txDataValid),
        .txByteData(txByteData),
        .txActive(txActive),
        .serialDataStream(serialDataStream),
        .done(done)
    );

    uart_rx #(
        .CYCLES_PER_BIT(CYCLES_PER_BIT)
    ) rx_inst (
        .clock(clock),
        .serialDataStream(serialDataStream),
        .rxDataValid(rxDataValid),
        .rxByteData(rxByteData)
    );

    always #(CLK_PERIOD/2) clock = ~clock;

    initial begin
        $dumpfile("uart_tb.vcd");
        $dumpvars(0, uart_tb);

        clock = 0;
        txDataValid = 0;
        txByteData = 0;

        repeat (10) @(posedge clock);

        send_byte(8'hA5);
        send_byte(8'h3C);
        send_byte(8'hFF);
        send_byte(8'h00);

        repeat (1000) @(posedge clock);
        $display("TEST COMPLETE");
        $finish;
    end

    task send_byte(input [7:0] data);
        int timeout;

        begin
            $display("Sending byte %h", data);

            @(posedge clock);
            txByteData <= data;
            txDataValid <= 1;

            @(posedge clock);
            txDataValid <= 0;

            // Wait for done with timeout
            timeout = 0;
            while (done !== 1) begin
                @(posedge clock);
                timeout++;
                if (timeout > 100000) begin
                    $display("ERROR: TX done timeout!");
                    $finish;
                end
            end

            // Wait for RX valid with timeout
            timeout = 0;
            while (rxDataValid !== 1) begin
                @(posedge clock);
                timeout++;
                if (timeout > 100000) begin
                    $display("ERROR: RX valid timeout!");
                    $finish;
                end
            end

            if (rxByteData !== data) begin
                $display("ERROR: Sent %h, Received %h", data, rxByteData);
            end else begin
                $display("PASS: Sent %h, Received %h", data, rxByteData);
            end
        end
    endtask

endmodule   