class mac_env extends uvm_env;
	`uvm_component_utils(mac_env)

	xgmii_agent		      xgmii_agent_inst;
	axis_agent 		      axis_agent_inst; 
	scoreboard		      scb;
	virtual_sequencer   virtual_seqr;
  reference_model     ref_model;

  uvm_tlm_fifo#(xgmii_seq_item)  xgmii_send;
  uvm_tlm_fifo#(udp_seq_item)    udp_send;
  
	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction

	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		xgmii_agent_inst = xgmii_agent::type_id::create("xgmii_agent_inst", this);
	  axis_agent_inst   = axis_agent::type_id::create("axis_agent_inst", this);
		virtual_seqr     = virtual_sequencer::type_id::create("virtual_seqr", this);
		scb              = scoreboard::type_id::create("scb", this);
		ref_model        = reference_model::type_id::create("ref_model", this);
    // TLM FIFOs
    udp_send         = new("udp_send",   this, 8);
    xgmii_send       = new("xgmii_send", this, 8);
   endfunction

	function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);

		// ---------------- XGMII ----------------
		virtual_seqr.xgmii_sequencer_inst = xgmii_agent_inst.seqr;

		// Expected XGMII stream
		xgmii_agent_inst.mon.dut_write.connect(ref_model.mon_in);
    ref_model.xgmii_send.connect(xgmii_send.put_export);
    scb.xgmii_send.connect(xgmii_send.get_export);
		// Actual XGMII stream
		xgmii_agent_inst.mon.dut_read.connect(scb.xgmii_out_port);

		// ---------------- UDP ----------------
		virtual_seqr.axis_sequencer_inst = axis_agent_inst.seqr;

		// Expected UDP stream
		axis_agent_inst.mon.ap_s_udp.connect(ref_model.udp_in);
    ref_model.udp_send.connect(udp_send.put_export);
    scb.udp_send.connect(udp_send.get_export);

		// Actual UDP stream
		axis_agent_inst.mon.ap_m_udp.connect(scb.udp_out_port);
	endfunction
endclass : mac_env