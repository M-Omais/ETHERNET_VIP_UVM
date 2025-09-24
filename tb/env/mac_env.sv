class mac_env extends uvm_env;
	`uvm_component_utils(mac_env)

	xgmii_agent		xgmii_agent_inst;
	udp_agent 		udp_agent_inst; // one agent for now
	scoreboard		scb;
	virtual_sequencer virtual_seqr;

	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction

	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		xgmii_agent_inst = xgmii_agent::type_id::create("xgmii_agent_inst", this);
	    udp_agent_inst = udp_agent::type_id::create("udp_agent_inst", this);
		virtual_seqr = virtual_sequencer::type_id::create("virtual_seqr", this);
		scb = scoreboard::type_id::create("scb", this);
	endfunction

	virtual function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		// Connect both monitor ports to scb
		virtual_seqr.xgmii_sequencer_inst = xgmii_agent_inst.sqr;
		virtual_seqr.udp_sequencer_inst = udp_agent_inst.seqr;
		xgmii_agent_inst.mon.dut_write.connect(scb.in_port);
		xgmii_agent_inst.mon.dut_read.connect(scb.out_port);
	endfunction

endclass : mac_env