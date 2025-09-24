interface xgmii_if(input bit clk, input bit rst_n);

	logic [63:0]	data;
	logic [7:0]	ctrl;
	logic [63:0]	tdata;
	logic [7:0]	tctrl;


endinterface : xgmii_if