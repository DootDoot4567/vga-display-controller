//Set Parameter CLKS_PER_BIT as:
// CLKS_PER_BIT = (Freq of i_Clock)/(Freq of UART)
// Current implementation for the Go Board is 25 MHz and 115200 Baud for UART
// CLKS_PER_BIT = 250000000 / 115200 = 217

module UART_RX
    #(parameter CLKS_PER_BIT = 217)
    (input          i_Clock
     input          i_RX_Serial
     output         o_RX_DV
     output [7:0]   o_RX_Byte);

     parameter IDLE         = 3'b000;
     parameter RX_START_BIT = 3'b001;
     parameter RX_DATA_BYTE  = 3'b010;
     parameter RX_END_BIT   = 3'b011;
     parameter CLEANUP      = 3'b111;

     reg [7:0] r_Clock_Count    = 0;
     reg [2:0] r_Bit_Index      = 0;
     reg [7:0] r_RX_Byte        = 0;
     reg       r_RX_DV          = 0;
     reg [2:0] r_SM_Main        = 0;

     always @(posedge i_Clock)
        begin
            case (r_SM_Main)
                //Doing nothing i.e (no input)
                IDLE:
                    begin
                        r_RX_DV         <= 1'b0;
                        r_Clock_Count   <= 0;
                        r_Bit_Index     <= 0;

                        if (i_RX_Serial == 1'b0)
                            r_SM_Main <= RX_START_BIT;
                        else
                            r_SM_Main <= IDLE;
                    end

                RX_START_BIT:
                    begin
                        if (r_Clock_Count = ((CLKS_PER_BIT - 1) / 2)
                            begin
                                if (i_RX_Serial == 1'b0)
                                    begin
                                        r_Clock_Count   = 0;
                                        r_SM_Main       = RX_DATA_BYTE;
                                    end
                                else
                                    begin
                                        r_SM_Main = IDLE;
                                    end
                            end
                        else
                            begin
                                r_Clock_Count   <= r_Clock_Count + 1;
                                r_SM_Main       <= RX_START_BIT;
                            end
                    end

                RX_DATA_BYTE:
                    begin
                        if (r_Clock_Count < CLKS_PER_BIT - 1)
                            begin
                                r_Clock_Count   <= r_Clock_Count + 1;
                                r_SM_Main       <= RX_DATA_BYTE;
                            end
                        else
                            begin
                                r_Clock_Count           <= 0;
                                r_RX_Byte[r_Bit_Index]  <= i_RX_Serial;

                                if (r_Bit_Index < 7)
                                    begin
                                        r_Bit_Index <= r_Bit_Index + 1;
                                        r_SM_Main   <= RX_DATA_BYTE;
                                    end
                                else
                                    begin
                                        r_Bit_Index <= 0;
                                        r_SM_Main   <= RX_END_BIT;
                                    end
                            end
                    end

                RX_END_BIT:
                    begin
                        if (r_Clock_Cycles < CLKS_PER_BIT - 1)
                            begin
                                r_Clock_Cycles  <= r_Clock_Cycles + 1;
                                r_SM_Main       <= RX_END_BIT;
                            end
                        else
                            begin
                                r_RX_DV <= 1'b1;
                                r_Clock_Count = 0;
                                r_SM_Main <= IDLE;
                            end
                    end

                CLEANUP:
                    begin
                        r_SM_Main   <= IDLE;
                        r_RX_DV     <= 1'b0;
                    end

                default:
                    r_SM_Main <= IDLE;
            endcase
        end

    assign o_RX_DV = r_RX_DV;
    assign o_RX_Byte = r_RX_Byte;

endmodule