
`timescale 1fs/1fs

`include "params.sv"
`include "classes.sv"

module s_axilite_interview_tb();

    event start_clocks;
  	event start_s_axilite_dummy;
  
    logic cpu_clk, axi_clk;
    string testtype;
  	string testtype_upper;
  
  	real CPU_CLK_PERIOD_FULL;
  	real CPU_CLK_PERIOD_HALF;
  	real AXI_CLK_PERIOD_FULL;
  	real AXI_CLK_PERIOD_HALF;

// Dummy CPU clock
    initial 
    begin
      cpu_clk = 0;
      //CPU_CLK_PERIOD_FULL = (1.0/($itor(CPU_FREQ)))*1000000000.0;
  	  //CPU_CLK_PERIOD_HALF = CPU_CLK_PERIOD_FULL/2.0;
      wait(start_clocks.triggered);
      cpu_clk = 1;
      //$display("CPU_CLK_PERIOD_HALF = %f", CPU_CLK_PERIOD_HALF);
      forever #5ns cpu_clk = ~cpu_clk;
    end

// M_axilite bus clock
    initial 
    begin
      axi_clk = 0;
      //AXI_CLK_PERIOD_FULL = (1.0/($itor(AXI_FREQ)))*1000000000.0;
      //AXI_CLK_PERIOD_HALF = AXI_CLK_PERIOD_FULL/2.0;
      wait(start_clocks.triggered);
      axi_clk = 1;
      //$display("AXI_CLK_PERIOD_HALF = %f", AXI_CLK_PERIOD_HALF);
      forever #50ns axi_clk = ~axi_clk;
    end
  
// waveforms
	initial
    begin
   		$dumpfile("dump.vcd");
  		$dumpvars;
    end

//cpu 
  
    cpu_con_m_axilite cpu_m_axilite_intf(axi_clk);
    my_cpu_class dummy_cpu;
  
  	//write
  	logic [(ADDRESS_WIDTH)-1:0] tb_w_addr;
  	logic [(DATA_WIDTH)-1:0] tb_w_data;
  	//read
  	logic [(ADDRESS_WIDTH)-1:0] tb_r_addr;
  	logic [(DATA_WIDTH)-1:0] tb_r_data;

    initial 
    begin
    	dummy_cpu = new(cpu_m_axilite_intf);
        //start clocks
        #1us ->start_clocks;
        //undo reset
        dummy_cpu.cpu_m_axilite_intf.rstn = 1'b1;
      	#100ns;
      
        //testcheck
        if($value$plusargs("testtype=%s", testtype))
        begin
          	testtype_upper = testtype.toupper();
          
            case(testtype_upper)
            "WRITE":
                begin
                  $display("CPU starting tb write sequence...");
                  tb_w_addr = $urandom_range(S_AXILITE_START_ADDR, S_AXILITE_START_ADDR+(S_AXILITE_NUM_ADDR-1));
                  tb_w_data = $urandom_range(0, 1 << (DATA_WIDTH-1));
                  $display("\nCPU Initiating write for Addr: %h with Data: %h", tb_w_addr, tb_w_data);
                  
                  dummy_cpu.m_axilite_write(tb_w_addr, tb_w_data, 0);
                end

            "READ" :
                begin
                  fork
                    begin
                      $display("CPU starting tb read sequence...");
                      tb_r_addr = $urandom_range(S_AXILITE_START_ADDR, S_AXILITE_START_ADDR+(S_AXILITE_NUM_ADDR-1));
                      tb_r_data = 'h0;
                      $display("\nCPU initiating read for Addr: %h", tb_r_addr);

                      dummy_cpu.m_axilite_read(tb_r_addr, 0, tb_r_data);
                      $display("\nCPU received read data: %h", tb_r_data);
                    end
                    
                    begin
                      #10us;
                    end
                  join_any
                end

            default:
                begin            
                	$error("Argument: '+testtype' specified does not match with preexisting tests");
                end
            endcase
        end

        else
        begin
            $error("Argument: '+testtype' not specified in run command...");
        end
      
      	#10us;
      	$finish;
    end

//s_axi
  	logic						s_axilite_rstn;
  
  	/*logic [(ADDRESS_WIDTH)-1:0] M_LITE_W_ADDRESS;
   	logic                       M_LITE_W_ADDRESS_VALID;
  	logic [(DATA_WIDTH)-1:0]    M_LITE_W_DATA;
    logic                       M_LITE_W_DATA_VALID;
    logic                       M_LITE_W_ACK_READY;
  	logic [(ADDRESS_WIDTH)-1:0] M_LITE_R_ADDRESS;
    logic                       M_LITE_R_ADDRESS_VALID;
    logic                       M_LITE_R_ACK_READY;*/
  
  m_axilite_con_s_axilite axilite_m_s_intf(axi_clk);
    my_s_axilite_class dummy_s_axilite;

    initial
    begin
      dummy_s_axilite = new(axilite_m_s_intf,
                            s_axilite_rstn/*,
                            M_LITE_W_ADDRESS,
                            M_LITE_W_ADDRESS_VALID,
                            M_LITE_W_DATA,
                            M_LITE_W_DATA_VALID,
                            M_LITE_W_ACK_READY,
                            M_LITE_R_ADDRESS,
                            M_LITE_R_ADDRESS_VALID,
                            M_LITE_R_ACK_READY*/
        					);
      
      	dummy_s_axilite.randomize_mem();
      
      	s_axilite_rstn = 1'b1;
      
        wait(start_clocks.triggered);
      
		#1ns ->start_s_axilite_dummy;
    end
  
  	always@(posedge axi_clk or negedge s_axilite_rstn or start_s_axilite_dummy)
    begin
      if(~s_axilite_rstn)
      begin
        dummy_s_axilite.zeroout();
      end
      
      else
      begin
        dummy_s_axilite.write_read();
      end
    end

    // 1. cpu write to axi slave
    // 2. cpu read from axi slave
    // axi slave for both cases... must have randomized memory

  master_axilite #(.PARAM_A_W(ADDRESS_WIDTH), .PARAM_D_W(DATA_WIDTH), .PARAM_TIMEOUT(10))
                        ma0
                        (
                          .cpu_intf(cpu_m_axilite_intf),
                          .s_axilite_intf(axilite_m_s_intf)
                        );

endmodule
