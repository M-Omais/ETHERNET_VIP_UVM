class sq_item extends uvm_sequence_item;

	`uvm_object_utils(sq_item)
	//Eth header fields
	rand bit [47:0] dst_addr;
	rand bit [47:0] src_addr;
	rand bit [15:0] eth_type;
	//IP header fields
	rand bit [31:0] src_ip;
	rand bit [31:0] dst_ip;
	// UDP header fields
	rand bit [15:0] src_port;
	rand bit [15:0] dst_port;
	// Payload
	rand logic [7:0] payload[];
	logic [63:0]  data_out[]; 
	logic [7:0]  ctrl_out[];

	function new(string name = "sq_item");
		super.new(name);
	endfunction
	// Method to convert the transaction to a string for printing
	virtual function string convert2string();
	    return $sformatf(" SRC MAC: %h\n DST MAC: %h\n SRC IP: %h\n DST IP: %h\n SRC PORT: %0d\n DST PORT: %0d\n PAYLOAD LEN: %0d\n",
							src_addr, dst_addr, src_ip, dst_ip, src_port, dst_port, payload.size());
	endfunction

	constraint payload_size_c {
    if (eth_type == 16'h0806)
        payload.size() == 0;       // ARP → no payload
    else
        payload.size() == 256;  // otherwise normal constraint
	}

	virtual function int data_create();
	    longint mac_src, mac_dst;
	    int ip_src, ip_dst;
	    int sport, dport;
	    byte payload_bytes[];
	    int payload_len;
	    longint dataout[64];
	    longint ctrlout[64];
	    int ret;
	    shortint eth_type_s;

	    // Map class fields
	    mac_src     = src_addr;
	    mac_dst     = dst_addr;
	    ip_src      = src_ip;
	    ip_dst      = dst_ip;
	    sport       = src_port;
	    dport       = dst_port;
	    payload_len = payload.size();
	    eth_type_s  = eth_type;

	    // Copy payload
	    payload_bytes = new[payload_len];
	    foreach (payload[i]) begin
	        payload_bytes[i] = payload[i];
	    end

	    // Call frame creation function
	    ret = xgmii_eth_frame_c(mac_src, mac_dst, ip_src, ip_dst,
	                            eth_type_s, sport, dport,
	                            payload_bytes, dataout, ctrlout);
		if (ret < 2) begin
			`uvm_error(get_type_name(), "DPI function xgmii_eth_frame_c failed");
		end else begin	
			`uvm_info(get_type_name(), "DPI function xgmii_eth_frame_c succeeded", UVM_LOW);
			// Copy output data to class fields
			data_out = new[ret];
			ctrl_out = new[ret];
			for (int i = 0; i < ret; i++) begin
				// `uvm_info(get_type_name(), $sformatf("dataout[%0d] = %h, ctrlout[%0d] = %h", i, dataout[i], i, ctrlout[i]), UVM_LOW);
			    data_out[i] = dataout[i];
			    ctrl_out[i] = ctrlout[i];
			end
		end
	    return ret;
	endfunction
	virtual function string print_data();
		string s = "Data Output:\n";
		foreach (data_out[i]) begin
			s = {s, $sformatf("data_out[%0d] = %h \t ctrl_out[%0d] = %h\n", i, data_out[i], i, ctrl_out[i])};
		end
		return s;
	endfunction

endclass