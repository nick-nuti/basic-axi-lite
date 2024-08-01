//axi-lite

module master_axilite #(
                        parameter PARAM_A_W = 32,
                        parameter PARAM_D_W = 8,

                        parameter PARAM_TIMEOUT = 10 // 10 clock cycles
                        )
                        (
                         cpu_con_m_axilite.slave        cpu_intf,
                         m_axilite_con_s_axilite.master s_axilite_intf
                         );

// AXI FSM Signals
  typedef enum {RST=0, IDLE=1, WRITE=2, READ=3, WRITE_ACK=4, READ_ACK=5, ERROR=6} axilite_fsm_stvec;
    axilite_fsm_stvec state_vec_current, state_vec_next;

// AXI Timeout Signals
    int timeout_counter;
    logic timeout_flag;

// CPU -> AXI Signals
    logic                   read_valid;
    logic [(PARAM_A_W)-1:0] r_address_buff;

    logic                   write_valid;
    logic [(PARAM_A_W)-1:0] w_address_buff;
    logic [(PARAM_D_W)-1:0] w_data_buff;

// AXI FSM
    always_ff @ (posedge cpu_intf.clk or negedge cpu_intf.rstn)
    begin
        if(~cpu_intf.rstn) state_vec_current <= RST;

        else state_vec_current      <= state_vec_next;
    end

    always_comb
    begin
        case(state_vec_current)
        RST:
            begin
                state_vec_next = IDLE;
            end

        IDLE:
            begin
                if(|cpu_intf.axi_error) state_vec_next = ERROR;

                else
                begin
                    if(read_valid) state_vec_next = READ;

                    else if(write_valid) state_vec_next = WRITE;

                    else state_vec_next = IDLE;
                end
            end

        WRITE:
            begin
                // good enough for this implementation
                if(s_axilite_intf.S_LITE_W_ADDRESS_READY && s_axilite_intf.S_LITE_W_DATA_READY) state_vec_next = WRITE_ACK;
                else state_vec_next = WRITE;
            end

        READ:
            begin
                if(s_axilite_intf.S_LITE_R_ADDRESS_READY) state_vec_next = READ_ACK;
                else state_vec_next = READ;
            end

        WRITE_ACK:
            begin
                if(|cpu_intf.axi_error) state_vec_next = ERROR;

                else
                begin
                    if(s_axilite_intf.M_LITE_W_ACK_READY && s_axilite_intf.S_LITE_W_ACK)
                    begin
                        if(write_valid)
                        begin
                            state_vec_next = WRITE;
                        end

                        else
                        begin
                            state_vec_next = IDLE;
                        end
                    end

                    else state_vec_next = WRITE_ACK;
                end
            end

        READ_ACK:
            begin
                if(|cpu_intf.axi_error) state_vec_next = ERROR;

                else
                begin
                    if(s_axilite_intf.M_LITE_R_ACK_READY && s_axilite_intf.S_LITE_R_ACK)
                    begin
                        if(read_valid)
                        begin
                            state_vec_next = READ;
                        end

                        else
                        begin
                            state_vec_next = IDLE;
                        end
                    end
                    
                    else state_vec_next = READ_ACK;
                end
            end

        ERROR:
            begin
                state_vec_next = IDLE;
            end

        default:
            begin
                state_vec_next = IDLE;
            end

        endcase
    end

// AXI -> Receiver Signals
    assign s_axilite_intf.M_LITE_W_ADDRESS_VALID = (state_vec_current == WRITE) || (state_vec_current == WRITE_ACK);
    assign s_axilite_intf.M_LITE_W_DATA_VALID    = (state_vec_current == WRITE) || (state_vec_current == WRITE_ACK);
    assign s_axilite_intf.M_LITE_W_ACK_READY     = ~cpu_intf.cpu_stall; 

    assign s_axilite_intf.M_LITE_R_ADDRESS_VALID = (state_vec_current == READ) || (state_vec_current == READ_ACK);
    assign s_axilite_intf.M_LITE_R_ACK_READY     = ~cpu_intf.cpu_stall;

// AXI -> CPU ERROR SIGNAL
    assign cpu_intf.axi_error[0] = timeout_flag;
    assign cpu_intf.axi_error[1] = (read_valid && write_valid);
    assign cpu_intf.axi_error[2] = 0; //extra

// AXI -> CPU BUSY SIGNAL
  assign cpu_intf.axi_ready = ((state_vec_current == WRITE) || (state_vec_current == READ)) ? 1'b0 : 1'b1;

// AXI -> receiver signals
    always_comb
    begin
        if(state_vec_current == WRITE)
        begin
            s_axilite_intf.M_LITE_W_ADDRESS    = w_address_buff;
            s_axilite_intf.M_LITE_W_DATA       = w_data_buff;
        end

        else if(state_vec_current == READ || state_vec_current <= IDLE)
        begin
            s_axilite_intf.M_LITE_W_ADDRESS    = 'd0;
            s_axilite_intf.M_LITE_W_DATA       = 'd0;
        end

        else
        begin
            s_axilite_intf.M_LITE_W_ADDRESS    = s_axilite_intf.M_LITE_W_ADDRESS;
            s_axilite_intf.M_LITE_W_DATA       = s_axilite_intf.M_LITE_W_DATA;
        end
    end

    always_comb
    begin
        if(state_vec_current == READ)
        begin
            s_axilite_intf.M_LITE_R_ADDRESS    = r_address_buff;
        end

        else if(state_vec_current == WRITE || state_vec_current <= IDLE)
        begin
            s_axilite_intf.M_LITE_R_ADDRESS    = 'd0;
        end

        else
        begin
            s_axilite_intf.M_LITE_R_ADDRESS    = s_axilite_intf.M_LITE_R_ADDRESS;
        end
    end

// AXI -> CPU
    always_comb
    begin
        if((state_vec_current == READ_ACK) && s_axilite_intf.S_LITE_R_ACK)
        begin
            cpu_intf.axi_cpu_r_data = s_axilite_intf.S_LITE_R_DATA;
        end

        else cpu_intf.axi_cpu_r_data = 'h0;
    end

// READ AND WRITE ACK TIMEOUT
    always_ff @ (posedge cpu_intf.clk or negedge cpu_intf.rstn)
    begin
        if(~cpu_intf.rstn)
        begin
            timeout_flag    <= 0;
            timeout_counter <= 0;
        end

        else
        begin
            // I only want a timeout if delay is caused by the slave device...
            if(((state_vec_current == WRITE_ACK) && s_axilite_intf.M_LITE_W_ACK_READY) ||
               ((state_vec_current == READ_ACK) && s_axilite_intf.M_LITE_R_ACK_READY)
               )
            begin
                if(timeout_counter < PARAM_TIMEOUT)
                begin
                    timeout_flag    <= 0;
                    timeout_counter <= timeout_counter + 1;
                end

                else
                begin
                    timeout_flag    <= 1;
                    timeout_counter <= timeout_counter;
                end
            end

            else
            begin
                timeout_flag    <= 0;
                timeout_counter <= 0;
            end
        end
    end

// CPU -> AXI
    assign read_valid = cpu_intf.cpu_read;

    always_ff @ (posedge cpu_intf.clk or negedge cpu_intf.rstn)
    begin
        if(~cpu_intf.rstn)
        begin
            r_address_buff  <= 'd0;
        end

        else
        begin
            // lookahead so axi master can read from slave immediately 
          if(((state_vec_current == IDLE) || (state_vec_current == READ_ACK)) && read_valid)
            begin
                r_address_buff  <= cpu_intf.cpu_axi_r_addr;
            end
          
            // if cpu is not looking for master to write again, we can clear the write buffers
            else if((state_vec_current == READ_ACK) && ~read_valid)
            begin
                r_address_buff  <= 'd0;
            end

            else
            begin
                r_address_buff  <= r_address_buff;
            end
        end
    end

    assign write_valid = cpu_intf.cpu_write;

    always_ff @ (posedge cpu_intf.clk or negedge cpu_intf.rstn)
    begin
        if(~cpu_intf.rstn)
        begin
            w_address_buff  <= 'd0;
            w_data_buff     <= 'd0;
        end

        else
        begin
            // lookahead so axi master can write to slave immediately 
            if(state_vec_current == IDLE)
            begin
                w_address_buff  <= cpu_intf.cpu_axi_w_addr;
                w_data_buff     <= cpu_intf.cpu_axi_w_data;
            end

            // lookahead if cpu wants a write on the very next clock cycle
            else if((state_vec_current == WRITE_ACK) && write_valid)
            begin
                w_address_buff  <= cpu_intf.cpu_axi_w_addr;
                w_data_buff     <= cpu_intf.cpu_axi_w_data;
            end

            // if cpu is not looking for master to write again, we can clear the write buffers
            else if((state_vec_current == WRITE_ACK) && ~write_valid)
            begin
                w_address_buff  <= 'd0;
                w_data_buff     <= 'd0;
            end

            else
            begin
                w_address_buff  <= w_address_buff;
                w_data_buff     <= w_data_buff;
            end
        end
    end

endmodule
