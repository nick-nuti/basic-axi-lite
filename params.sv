
parameter int unsigned CPU_FREQ = 100e6; // not used currently
parameter int unsigned AXI_FREQ = 10e6;	 // not used currently

parameter ADDRESS_WIDTH = 32;
parameter DATA_WIDTH = 32;

parameter S_AXILITE_START_ADDR = 'hAAA;
parameter S_AXILITE_NUM_ADDR   = 25; // 25 addresses

parameter LARGEST_WIDTH = (ADDRESS_WIDTH > DATA_WIDTH) ? ADDRESS_WIDTH : DATA_WIDTH;
