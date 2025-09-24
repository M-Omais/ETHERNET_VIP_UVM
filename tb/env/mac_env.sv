// Env = container for agent(s), scoreboard, coverage
class mac_env extends uvm_env;
	`uvm_component_utils(mac_env)

	xgmii_agent		xgmii_agent_inst;
	udp_agent 		udp_agent_inst; // one agent for now
	scoreboard		scb;

	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction

	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		xgmii_agent_inst = xgmii_agent::type_id::create("xgmii_agent_inst", this);
	    udp_agent_inst = udp_agent::type_id::create("udp_agent_inst", this);
		scb = scoreboard::type_id::create("scb", this);
	endfunction

	virtual function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		// Connect both monitor ports to scb
		xgmii_agent_inst.mon.dut_write.connect(scb.in_port);
		xgmii_agent_inst.mon.dut_read.connect(scb.out_port);
	endfunction

endclass : mac_env