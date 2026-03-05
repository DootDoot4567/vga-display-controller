module UART_TX
    #(parameter CLKS_PER_BIT = 217)
    (input i_Clk,
     input i_TX_DV,
     input [7:0] i_TX_Byte,
     output o_TX_Active,
     output reg o_TX_Serial,
     output o_TX_Done);

    parameter IDLE         = 3'b000;
    parameter TX_START_BIT = 3'b001;
    parameter TX_DATA_BYTE = 3'b010;
    parameter TX_END_BIT   = 3'b011;
    parameter TX_CLEANUP   = 3'b111;


    reg [7:0]   r_Clk_Count = 0;
    reg [2:0]   r_Bit_Index = 0;
    reg [7:0]   r_TX_Byte   = 0;
    reg         r_TX_DV     = 0;
    reg [2:0]   r_SM_Main   = 0;

    always @(posedge i_Clk)
        begin

            o_TX_Done <= 1'b0;

            case(r_SM_Main)
                begin
                    IDLE:
                        begin
                            r_TX_Serial     <= 1'b1;
                            r_CLk_Count <= 0;
                            r_Bit_Index <= 0;

                            if (i_TX_DV == 1'b1)
                                begin
                                    r_TX_Byte   <= i_TX_Byte;
                                    r_SM_Main   <= TX_START_BIT;
                                    o_TX_Active <= 1'b1;
                                end
                            else
                                begin
                                    r_SM_Main <= IDLE;
                                end
                        end

                    TX_START_BIT:
                        begin
                            o_TX_Serial = 1'b0;

                            if (r_Clock_Count < CLKS_PER_BIT - 1)
                                begin
                                    r_Clock_count <= r_Clock_Count + 1;
                                    r_SM_Main <= TX_START_BIT;
                                end
                            else
                                begin
                                    r_Clock_Count <= 0;
                                    r_SM_Main <= TX_DATA_BYTE;
                                end
                        end

                    TX_DATA_BYTE:
                        begin
                            o_TX_Serial <= r_TX_Byte[r_Bit_Index];

                            if (r_Clock_Count < CLKS_PER_BIT - 1)
                                begin
                                    r_Clock_count <= r_Clock_Count + 1;
                                end
                            else
                                begin
                                    r_Clock_Count <= 1'b0;

                                    if (r_Bit_Index < 7)
                                        begin
                                            r_Bit_Index <= r_Bit_Index + 1;
                                            r_SM_Main   <= TX_DATA_BYTE;
                                        end
                                    else
                                        begin
                                            r_Bit_Index <= 1'b0;
                                            r_SM_Main <= TX_END_BIT;
                                        end
                                end
                        end

                    TX_END_BIT:
                        begin
                            o_TX_Serial <= 1'b1;

                            if (r_Clock_Count < CLKS_PER_BIT - 1)
                                begin
                                    r_Clock_Count <= r_Clock_Count + 1;
                                    r_SM_Main <= TX_END_BIT;
                                end
                            else
                                begin
                                    o_TX_Done <= 1'b1;
                                    r_Clock_Count <= 0;
                                    r_SM_Main <= CLEANUP;
                                    o_TX_Active <= 1'b0;
                                end
                        end

                    CLEANUP:
                        begin
                            o_TX_Done <= 1'b1;
                            r_SM_Main <= IDLE;
                        end

                    default:
                        r_SM_Main <= IDLE;
                end
            endcase
        end

endmodule