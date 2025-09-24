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
		forever begin
			wait(vif.rst_n);
			wait(!vif.rst_n);
			tr = sq_item::type_id::create("tr", this);
			seq_item_port.get_next_item(tr);
			vif.data <= 64'h0707070707070707; 
			vif.ctrl <= 64'hFFFFFFFFFFFFFFFF; 
			tr.src_addr = 48'h5a5152535455;
			tr.dst_addr = 48'h020000000000;
			tr.src_ip = 32'hc0a80164;
			tr.dst_ip = 32'hC0A80180;
			tr.src_port = 5678;
			tr.dst_port = 1234;
			// creating a payload of 256 bytes with incremental values
			// tr.payload = new[256];
			// for (i = 0; i < 256; i++) begin
			// 	tr.payload[i] = i;
			// end
			`uvm_info(get_type_name(), $sformatf("Received transaction: SRC MAC: %h, DST MAC: %h, SRC IP: %h, DST IP: %h, SRC PORT: %0d, DST PORT: %0d, PAYLOAD LEN: %0d",
				tr.src_addr, tr.dst_addr, tr.src_ip, tr.dst_ip, tr.src_port, tr.dst_port, tr.payload.size()), UVM_LOW);
			// Prepare parameters for DPI call
			mac_src = tr.src_addr;
			mac_dst = tr.dst_addr;
			ip_src = tr.src_ip;
			ip_dst = tr.dst_ip;
			sport = tr.src_port;
			dport = tr.dst_port;
			payload_len = tr.payload.size();
			payload_bytes = new[256];
			for (i = 0; i < 256; i++) begin
				payload_bytes[i] = i;
			end
			vif.rst_n = 0;
			@(posedge vif.clk);
			vif.rst_n = 1;
			for (i = 0; i < 10; i++) begin
				@(posedge vif.clk);
			end
			
			vif.rst_n = 0;
			@(posedge vif.clk);
			// Call the DPI function to generate the Ethernet frame
			ret = xgmii_eth_frame_c(mac_src, mac_dst, ip_src, ip_dst, sport, dport, payload_bytes, data_out, ctrl_out);
			if (ret < 2) begin
				`uvm_error(get_type_name(), "DPI function xgmii_eth_frame_c failed");
			end else begin
				`uvm_info(get_type_name(), "DPI function xgmii_eth_frame_c succeeded", UVM_LOW);
			end
			// Drive the interface signals based on the transaction item 'tr'
			for (i = 0; i < ret; i++) begin
					@(posedge vif.clk);
				// if (ctrl_out[i] !== 0) begin
					vif.data <= data_out[i]; 
					vif.ctrl <= ctrl_out[i]; 
					`uvm_info(get_type_name(), $sformatf("Driving data: %h, ctrl: %0h at index %0d", data_out[i], ctrl_out[i], i), UVM_HIGH);
					// Add any necessary timing control here
				// end
			end
			vif.data <= 64'h0707070707070707; 
			vif.ctrl <= 64'hFFFFFFFFFFFFFFFF; 
			// Add any necessary timing control here
			@(posedge vif.clk);
			
			#5010;
			tr.src_addr = 48'h5a5152535455;
			tr.dst_addr = 48'h020000000000;
			tr.src_ip = 32'hc0a80164;
			tr.dst_ip = 32'hC0A80180;
			ret = xgmii_arp_frame_c(mac_src, mac_dst, ip_src, ip_dst, data_out, ctrl_out);
			if (ret < 2) begin
				`uvm_error(get_type_name(), "DPI function xgmii_arp_frame_c failed");
				$display("%d", ret);
			end else begin
				`uvm_info(get_type_name(), "DPI function xgmii_arp_frame_c succeeded", UVM_LOW);
			end
			for (i = 0; i < ret; i++) begin
					@(posedge vif.clk);
				// if (ctrl_out[i] !== 0) begin
					vif.data <= data_out[i]; 
					vif.ctrl <= ctrl_out[i]; 
					`uvm_info(get_type_name(), $sformatf("Driving data: %h, ctrl: %0h at index %0d", data_out[i], ctrl_out[i], i), UVM_HIGH);
					// Add any necessary timing control here
				// end
			end
			vif.data <= 64'h0707070707070707; 
			vif.ctrl <= 64'hFFFFFFFFFFFFFFFF; 
			#10ns
			seq_item_port.item_done();
		end
	endtask

endclass