class xgmii_driver extends uvm_driver#(sq_item);
	`uvm_component_utils(xgmii_driver)
	longint mac_src, mac_dst;
	int ip_src, ip_dst;
	int sport, dport;
	byte payload_bytes[];
	int payload_len;
	longint data_out[64];
	longint ctrl_out[64];
	int i,ret;
	virtual xgmii_if  vif;
	virtual axi_stream_if axis_i;
	function new(string name, uvm_component parent);
		super.new(name, parent);
		if (!uvm_config_db#(virtual xgmii_if)::get(this, "", "vif", vif)) begin
			string comp_path = this.get_full_name();         // UVM hierarchy e.g. uvm_test_top.env.agent.driver
			`uvm_fatal(get_type_name(),
				$sformatf("UNABLE TO GET VIRTUAL INTERFACE 'vif' — component: %s", comp_path)
			)
		end
		if (!uvm_config_db#(virtual axi_stream_if)::get(this, "", "vifa", axis_i)) begin
			string comp_path = this.get_full_name();         // UVM hierarchy e.g. uvm_test_top.env.agent.driver
			`uvm_fatal(get_type_name(),
				$sformatf("UNABLE TO GET VIRTUAL INTERFACE 'vif' — component: %s", comp_path)
			)
		end
	endfunction

	virtual task run_phase(uvm_phase phase);
		sq_item tr;
			wait(vif.rst_n);
			wait(!vif.rst_n);
		forever begin
			vif.data <= 64'h0707070707070707; 
			vif.ctrl <= 64'hFFFFFFFFFFFFFFFF; 
			tr = sq_item::type_id::create("tr", this);
			seq_item_port.get_next_item(tr);
			// creating a payload of 256 bytes with incremental values
			// tr.payload = new[256];
			// for (i = 0; i < 256; i++) begin
			// 	tr.payload[i] = i;
			// end
			`uvm_info("XGMII_DRIVER", $sformatf("Received transaction:\n%s", tr.convert2string()), UVM_LOW)
			// Prepare parameters for DPI call
			ret = tr.data_create();
			`uvm_info(get_type_name(), $sformatf("DPI function returned %0d bytes", ret), UVM_LOW);
			for (int i  = 0; i < ret; i++) begin
					vif.data <= tr.data_out[i]; 
					vif.ctrl <= tr.ctrl_out[i]; 
					@(posedge vif.clk);
			end
			vif.data <= 64'h0707070707070707; 
			vif.ctrl <= 64'hFFFFFFFFFFFFFFFF; 
			// #1ns
			seq_item_port.item_done();
		end
	endtask
 
  
  


endclass