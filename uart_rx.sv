//CYCLES_PER_BIT = 25 MHZ / 115000 Baud

module uart_rx #(
    parameter CYCLES_PER_BIT = 217;
) (
    input logic clock,
    input logic serialDataStream,

    output logic rxDataValid,
    output logic [7:0] rxByteData
);

    typedef enum{
        IDLE,
        START_BIT,
        DATA_BIT,
        END_BIT
    } state_t;

    state_t state;

    logic [7:0] counter;
    logic [7:0] data;
    logic [2:0] bitIndex;
    logic dataValid;

    always @(posedge clock)
        begin
            case(state)
                IDLE:
                    begin
                        dataValid <= 0;
                        count <= 0;
                        bitIndex <= 0;

                        if (serialDataStream === 1'b0)
                            state <= START_BIT;
                        else
                            state <= IDLE;
                    end
                START_BIT:
                    begin
                        if (count = (CYCLES_PER_BIT - 1) / 2)
                            begin
                                if (serialDataStream === 1'b0)
                                    begin
                                        count <= 0;
                                        state <= DATA_BIT;
                                    end
                                else
                                    begin
                                        state <= IDLE;
                                    end
                            end
                        else
                            begin
                                count <= count + 1;
                                state <= START_BIT;
                            end
                    end
                DATA_BIT:
                    begin
                        if (count < CYCLES_PER_BIT - 1)
                            begin
                                count <= count + 1;
                                state <= DATA_BIT;
                            end
                        else
                            begin
                                count <= 0;
                                data[bitIndex] <= serialDataStream;

                                if (bitIndex < 7)
                                    begin
                                        bitIndex <= bitIndex + 1;
                                        state <= DATA_BIT;
                                    end
                                else
                                    begin
                                        bitIndex <= 0;
                                        state <= END_BIT;
                                    end
                            end
                    end
                END_BIT:
                    begin
                        if (count < CYCLES_PER_BIT - 1)
                            begin
                                count <= count + 1;
                                state <= END_BIT;
                            end
                        else
                            begin
                                dataValid <= 1;
                                counter <= 0;
                                state <= IDLE;
                            end
                    end

                default:
                    state <= IDLE;
            endcase
        end


    assign rxDataValid = dataValid;
    assign rxByteData = data;

endmodule