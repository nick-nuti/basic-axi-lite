interface cpu_con_m_axilite(input clk);
  //logic						   clk;
  logic						   rstn;
  logic                        cpu_write;
  logic [(ADDRESS_WIDTH)-1:0]  cpu_axi_w_addr;
  logic [(DATA_WIDTH)-1:0]     cpu_axi_w_data;
  
  logic                        cpu_read;
  logic [(ADDRESS_WIDTH)-1:0]  cpu_axi_r_addr;
  logic [(DATA_WIDTH)-1:0]     axi_cpu_r_data;
  
  logic                        cpu_stall;
  logic [2:0]                  axi_error;
  logic                        axi_ready;
  
  modport master (
                  input clk,
                  output rstn,
                  output cpu_write,
                  output cpu_axi_w_addr,
                  output cpu_axi_w_data,
                  output cpu_read,
                  output cpu_axi_r_addr,
                  input axi_cpu_r_data,
                  output cpu_stall,
                  input axi_error,
                  input axi_ready
  			  	  );
 
  
  modport slave	 (
    			  input clk,
                  input rstn,
                  input cpu_write,
                  input cpu_axi_w_addr,
                  input cpu_axi_w_data,
                  input cpu_read,
                  input cpu_axi_r_addr,
                  output axi_cpu_r_data,
                  input cpu_stall,
                  output axi_error,
                  output axi_ready
  			  	  );
  
endinterface

interface m_axilite_con_s_axilite(input clk);

  logic [(ADDRESS_WIDTH)-1:0] M_LITE_W_ADDRESS;
  logic                       M_LITE_W_ADDRESS_VALID;
  logic [(DATA_WIDTH)-1:0]    M_LITE_W_DATA;
  logic                       M_LITE_W_DATA_VALID;
  logic                       M_LITE_W_ACK_READY;
  logic                       S_LITE_W_DATA_READY;                     
  logic                       S_LITE_W_ADDRESS_READY;
  logic                       S_LITE_W_ACK;
  logic [(ADDRESS_WIDTH)-1:0] M_LITE_R_ADDRESS;
  logic                       M_LITE_R_ADDRESS_VALID;
  logic                       M_LITE_R_ACK_READY;
  logic [(DATA_WIDTH)-1:0]    S_LITE_R_DATA;
  logic                       S_LITE_R_ADDRESS_READY;
  logic                       S_LITE_R_ACK;

  modport master (
    			  //write
                  output M_LITE_W_ADDRESS,
                  output M_LITE_W_ADDRESS_VALID,
                  output M_LITE_W_DATA,
                  output M_LITE_W_DATA_VALID,
                  output M_LITE_W_ACK_READY,
                  input  S_LITE_W_DATA_READY,
                  input  S_LITE_W_ADDRESS_READY,
    			  input  S_LITE_W_ACK,
    			  //read
    			  output M_LITE_R_ADDRESS,
    			  output M_LITE_R_ADDRESS_VALID,
                  output M_LITE_R_ACK_READY,
                  input  S_LITE_R_DATA,
                  input  S_LITE_R_ADDRESS_READY,
                  input  S_LITE_R_ACK
  			  	  );
  
  modport slave	 (
    			  input clk,
    			  //write
                  input  M_LITE_W_ADDRESS,
                  input  M_LITE_W_ADDRESS_VALID,
                  input  M_LITE_W_DATA,
                  input  M_LITE_W_DATA_VALID,
                  input  M_LITE_W_ACK_READY,
                  output S_LITE_W_DATA_READY,
                  output S_LITE_W_ADDRESS_READY,
    			  output S_LITE_W_ACK,
    			  //read
    			  input  M_LITE_R_ADDRESS,
    			  input  M_LITE_R_ADDRESS_VALID,
                  input  M_LITE_R_ACK_READY,
                  output S_LITE_R_DATA,
                  output S_LITE_R_ADDRESS_READY,
                  output S_LITE_R_ACK
  			  	  );

endinterface

class my_cpu_class;
    virtual cpu_con_m_axilite.master cpu_m_axilite_intf;
	
  	//logic					 ref_clk_in;
  	
  	logic [2:0]              ref_axi_error;
    logic                    ref_axi_ready;
  
  	logic [(DATA_WIDTH)-1:0] ref_cpu_r_data;

    function new(
      			 virtual cpu_con_m_axilite.master cpu_m_axilite_intf
      			 // clk that gets passed to m_axilite dut
      			 //ref logic					  ref_clk_in
                 );
      
        this.cpu_m_axilite_intf 			= cpu_m_axilite_intf;

        //this.ref_clk_in						= ref_clk_in;

        zeroout();

        //assigninclk();
      
    endfunction

    function void zeroout();
        //cpu_m_axilite_intf.clk				= 'd0;
        cpu_m_axilite_intf.rstn				= 'd0;
        cpu_m_axilite_intf.cpu_write		= 'd0;
        cpu_m_axilite_intf.cpu_axi_w_addr	= 'd0;
        cpu_m_axilite_intf.cpu_axi_w_data	= 'd0;
        cpu_m_axilite_intf.cpu_read			= 'd0;
        cpu_m_axilite_intf.cpu_axi_r_addr	= 'd0;
        cpu_m_axilite_intf.cpu_stall		= 'd0;
    endfunction
  
  	/*function void assigninclk();
      	cpu_m_axilite_intf.clk = ref_clk_in;
  	endfunction*/
  
  	task m_axilite_write(
      					  input [(ADDRESS_WIDTH)-1:0] cpu_axi_w_addr,
      					  input [(DATA_WIDTH)-1:0] cpu_axi_w_data,
                          
                  		  input cpu_stall
    					  );
	begin
    	// keep track of these:
      	//output axi_error,
      	//output axi_ready
        // Also... need to keep track of rst_n at some point
      	$display("\nM_AXILITE function m_axilite_write()...");
      	cpu_m_axilite_intf.cpu_axi_w_addr	= cpu_axi_w_addr;
        cpu_m_axilite_intf.cpu_axi_w_data	= cpu_axi_w_data;
      
    	cpu_m_axilite_intf.cpu_write		= 'd1;
        @(posedge cpu_m_axilite_intf.clk);
        cpu_m_axilite_intf.cpu_write		= 'd0;
        @(posedge cpu_m_axilite_intf.axi_ready);
    end
    endtask
      
    task m_axilite_read(
      					input  [(ADDRESS_WIDTH)-1:0] cpu_axi_r_addr,
      					input 						 cpu_stall,
      					output [(DATA_WIDTH)-1:0] 	 axi_cpu_r_data
    					);
	begin
     	// keep track of these:
      	//output axi_error,
      	//output axi_ready
      	// Also... need to keep track of rst_n at some point
      $display("\nM_AXILITE function m_axilite_read()...");
      
        cpu_m_axilite_intf.cpu_axi_r_addr	= cpu_axi_r_addr;

        cpu_m_axilite_intf.cpu_read		= 'd1;
        @(posedge cpu_m_axilite_intf.clk);
        cpu_m_axilite_intf.cpu_read		= 'd0;
        @(posedge cpu_m_axilite_intf.axi_ready);
      	@(posedge cpu_m_axilite_intf.clk) axi_cpu_r_data = cpu_m_axilite_intf.axi_cpu_r_data;
    end
    endtask
endclass

class my_s_axilite_class;
    virtual m_axilite_con_s_axilite.slave m_axilite_s_axilite_intf;
  
  	logic rst_n;
  
  	// s_axilite_mem
  	logic [(DATA_WIDTH)-1:0] s_axilite_mem [S_AXILITE_START_ADDR+(S_AXILITE_NUM_ADDR-1):S_AXILITE_START_ADDR];
  
  	// ref logic that goes out to s_axilite device
  	/*logic [(ADDRESS_WIDTH)-1:0] ref_M_LITE_W_ADDRESS;
    logic                       ref_M_LITE_W_ADDRESS_VALID;
	logic [(DATA_WIDTH)-1:0]    ref_M_LITE_W_DATA;
  	logic                       ref_M_LITE_W_DATA_VALID;
  	logic                       ref_M_LITE_W_ACK_READY;
  	logic [(ADDRESS_WIDTH)-1:0] ref_M_LITE_R_ADDRESS;
  	logic                       ref_M_LITE_R_ADDRESS_VALID;
  	logic                       ref_M_LITE_R_ACK_READY;*/
  
    function new(
      			 virtual m_axilite_con_s_axilite.slave m_axilite_s_axilite_intf,
       			 ref logic						 rst_n
      
      			 /*ref logic [(ADDRESS_WIDTH)-1:0] ref_M_LITE_W_ADDRESS,
                 ref logic                       ref_M_LITE_W_ADDRESS_VALID,
      			 ref logic [(DATA_WIDTH)-1:0]    ref_M_LITE_W_DATA,
                 ref logic                       ref_M_LITE_W_DATA_VALID,
                 ref logic                       ref_M_LITE_W_ACK_READY,
      			 ref logic [(ADDRESS_WIDTH)-1:0] ref_M_LITE_R_ADDRESS,
                 ref logic                       ref_M_LITE_R_ADDRESS_VALID,
                 ref logic                       ref_M_LITE_R_ACK_READY*/
     			 );
      
        this.m_axilite_s_axilite_intf 		= m_axilite_s_axilite_intf;
      
      	this.rst_n							= rst_n;

      /*
        this.ref_M_LITE_W_ADDRESS 			= ref_M_LITE_W_ADDRESS;
        this.ref_M_LITE_W_ADDRESS_VALID 	= ref_M_LITE_W_ADDRESS_VALID;
        this.ref_M_LITE_W_DATA 				= ref_M_LITE_W_DATA;
        this.ref_M_LITE_W_DATA_VALID 		= ref_M_LITE_W_DATA_VALID;
        this.ref_M_LITE_W_ACK_READY 		= ref_M_LITE_W_ACK_READY;
        this.ref_M_LITE_R_ADDRESS 			= ref_M_LITE_R_ADDRESS;
        this.ref_M_LITE_R_ADDRESS_VALID 	= ref_M_LITE_R_ADDRESS_VALID;
        this.ref_M_LITE_R_ACK_READY 		= ref_M_LITE_R_ACK_READY;*/
      
        zeroout();

        //ref_assign();
      
    endfunction

    function void zeroout();
        m_axilite_s_axilite_intf.S_LITE_W_DATA_READY		= 'd0;
        m_axilite_s_axilite_intf.S_LITE_W_ADDRESS_READY	= 'd0;
        m_axilite_s_axilite_intf.S_LITE_W_ACK				= 'd0;
        m_axilite_s_axilite_intf.S_LITE_R_DATA			= 'd0;
        m_axilite_s_axilite_intf.S_LITE_R_ADDRESS_READY	= 'd0;
        m_axilite_s_axilite_intf.S_LITE_R_ACK				= 'd0;
    endfunction
  
  	/*function void ref_assign();
        ref_M_LITE_W_ADDRESS 			= m_axilite_s_axilite_intf.M_LITE_W_ADDRESS;
        ref_M_LITE_W_ADDRESS_VALID 		= m_axilite_s_axilite_intf.M_LITE_W_ADDRESS_VALID;
        ref_M_LITE_W_DATA 				= m_axilite_s_axilite_intf.M_LITE_W_DATA;
        ref_M_LITE_W_DATA_VALID 		= m_axilite_s_axilite_intf.M_LITE_W_DATA_VALID;
        ref_M_LITE_W_ACK_READY 			= m_axilite_s_axilite_intf.M_LITE_W_ACK_READY;
        ref_M_LITE_R_ADDRESS 			= m_axilite_s_axilite_intf.M_LITE_R_ADDRESS;
        ref_M_LITE_R_ADDRESS_VALID 		= m_axilite_s_axilite_intf.M_LITE_R_ADDRESS_VALID;
        ref_M_LITE_R_ACK_READY 			= m_axilite_s_axilite_intf.M_LITE_R_ACK_READY;
    endfunction*/
  
  	function void randomize_mem();
      	$display("\nRandomizing S_AXILITE Device Memory Space:");
      	foreach(s_axilite_mem[i])
        begin
          s_axilite_mem[i] = $urandom_range(0, 1 << (DATA_WIDTH-1));
          $display("	ADDRESS: %h , DATA: %h", i, s_axilite_mem[i]);
        end
      	$display("\n");
  	endfunction
  
  	function void check_mem();
      $display("\Printing S_AXILITE Device Memory Space:");
      foreach(s_axilite_mem[i])
        begin
          $display("	ADDRESS: %h , DATA: %h", i, s_axilite_mem[i]);
        end
      $display("\n");
    endfunction
  
  	task write_read();
	begin
      $display("S_AXILITE waiting for message...");
      wait((m_axilite_s_axilite_intf.M_LITE_W_ADDRESS_VALID | m_axilite_s_axilite_intf.M_LITE_R_ADDRESS_VALID) == 1)
      
      if(m_axilite_s_axilite_intf.M_LITE_W_ADDRESS_VALID)
      begin
        //wait(m_axilite_s_axilite_intf.M_LITE_W_ADDRESS);
        wait(m_axilite_s_axilite_intf.M_LITE_W_ADDRESS_VALID && m_axilite_s_axilite_intf.M_LITE_W_DATA_VALID);
        if(m_axilite_s_axilite_intf.M_LITE_W_ADDRESS > S_AXILITE_START_ADDR+(S_AXILITE_NUM_ADDR-1) || 
           m_axilite_s_axilite_intf.M_LITE_W_ADDRESS < S_AXILITE_START_ADDR)
        begin
          $error("Requested write address: %h is out of slave memory range: [%h:%h]", 
                 m_axilite_s_axilite_intf.M_LITE_W_ADDRESS, 
				 S_AXILITE_START_ADDR+(S_AXILITE_NUM_ADDR-1), 
				 S_AXILITE_START_ADDR);
        end
        
        else
        begin
          $display("S_AXILITE device starting write sequence");
          //wait(m_axilite_s_axilite_intf.M_LITE_W_ADDRESS_VALID && m_axilite_s_axilite_intf.M_LITE_W_DATA_VALID);
          
          m_axilite_s_axilite_intf.S_LITE_W_DATA_READY 	= 1'b1;
          m_axilite_s_axilite_intf.S_LITE_W_ADDRESS_READY = 1'b1;
          
          @(posedge m_axilite_s_axilite_intf.clk);
          
           m_axilite_s_axilite_intf.S_LITE_W_DATA_READY 	= 1'b0;
           m_axilite_s_axilite_intf.S_LITE_W_ADDRESS_READY = 1'b0;
          
          s_axilite_mem[m_axilite_s_axilite_intf.M_LITE_W_ADDRESS] = m_axilite_s_axilite_intf.M_LITE_W_DATA;
          //repeat(5) @(posedge m_axilite_s_axilite_intf.clk);
          m_axilite_s_axilite_intf.S_LITE_W_ACK = 1'b1;
          
          wait(m_axilite_s_axilite_intf.M_LITE_W_ACK_READY == 1'b1);
          
          @(posedge m_axilite_s_axilite_intf.clk) m_axilite_s_axilite_intf.S_LITE_W_ACK = 1'b0;
          $display("S_AXILITE device ending write sequence");
          
          $display("S_AXILITE Device Address: %h now had Data: %h", 
                   m_axilite_s_axilite_intf.M_LITE_W_ADDRESS, 
                   s_axilite_mem[m_axilite_s_axilite_intf.M_LITE_W_ADDRESS]);
          
          check_mem();
        end
      end
      
      else if(m_axilite_s_axilite_intf.M_LITE_R_ADDRESS_VALID)
      begin
        wait(m_axilite_s_axilite_intf.M_LITE_R_ADDRESS_VALID);
        if(m_axilite_s_axilite_intf.M_LITE_R_ADDRESS > S_AXILITE_START_ADDR+(S_AXILITE_NUM_ADDR-1) || 
           m_axilite_s_axilite_intf.M_LITE_R_ADDRESS < S_AXILITE_START_ADDR)
        begin
          $error("Requested read address: %h is out of slave memory range: [%h:%h]", 
                   m_axilite_s_axilite_intf.M_LITE_R_ADDRESS, 
                   S_AXILITE_START_ADDR+(S_AXILITE_NUM_ADDR-1), 
                   S_AXILITE_START_ADDR);
        end
        
        else
        begin
          $display("S_AXILITE device starting read sequence");
          
          m_axilite_s_axilite_intf.S_LITE_R_ADDRESS_READY = 1'b1;
          
          @(posedge m_axilite_s_axilite_intf.clk);
        
          m_axilite_s_axilite_intf.S_LITE_R_ADDRESS_READY = 1'b0;
          
          m_axilite_s_axilite_intf.S_LITE_R_DATA = s_axilite_mem[m_axilite_s_axilite_intf.M_LITE_R_ADDRESS];
          m_axilite_s_axilite_intf.S_LITE_R_ACK = 1'b1;
          
          wait(m_axilite_s_axilite_intf.M_LITE_R_ACK_READY == 1'b1);
          
          @(posedge m_axilite_s_axilite_intf.clk) m_axilite_s_axilite_intf.S_LITE_R_ACK = 1'b0;
          
          $display("S_AXILITE device ending read sequence");
          
          $display("S_AXILITE Device Address: %h read out Data: %h", 
                   m_axilite_s_axilite_intf.M_LITE_R_ADDRESS, 
                   s_axilite_mem[m_axilite_s_axilite_intf.M_LITE_R_ADDRESS]);
        end
      end
      
      else
      begin
        $display("Something strange happened, exiting task: 'detect_w_r()'...");
      end
    end
  	endtask

endclass
