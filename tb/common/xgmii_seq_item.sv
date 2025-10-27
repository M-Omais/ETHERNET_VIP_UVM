class xgmii_seq_item extends uvm_sequence_item;

	//Eth header fields
	rand bit [47:0]   dst_addr;
	rand bit [47:0]   src_addr;
	rand bit [15:0]   eth_type;
	//IP header fields
	rand bit [31:0]   src_ip;
	rand bit [31:0]   dst_ip;
	// UDP header fields
	rand bit [15:0]   src_port;
	rand bit [15:0]   dst_port;
	// Payload
	rand logic [7:0]  payload[];
	bit [63:0]        data_out[]; 
	bit [7:0]         ctrl_out[];

  // Register this object with UVM factory
  `uvm_object_utils_begin(xgmii_seq_item)
    `uvm_field_int       (dst_addr,  UVM_ALL_ON)
    `uvm_field_int       (src_addr,  UVM_ALL_ON)
    `uvm_field_int       (eth_type,  UVM_ALL_ON)
    `uvm_field_int       (src_ip,    UVM_ALL_ON)
    `uvm_field_int       (dst_ip,    UVM_ALL_ON)
    `uvm_field_int       (src_port,  UVM_ALL_ON)
    `uvm_field_int       (dst_port,  UVM_ALL_ON)
    `uvm_field_array_int (payload,   UVM_ALL_ON)
    `uvm_field_array_int (data_out,  UVM_ALL_ON)
    `uvm_field_array_int (ctrl_out,  UVM_ALL_ON)
  `uvm_object_utils_end

	function new(string name = "xgmii_seq_item");
		super.new(name);
	endfunction

	// Method to convert the transaction to a string for printing
	virtual function string convert2string();
	    return $sformatf(" SRC MAC: %h\n DST MAC: %h\n SRC IP: %h\n DST IP: %h\n SRC PORT: %0d\n DST PORT: %0d\n PAYLOAD LEN: %0d\n",
							src_addr, dst_addr, src_ip, dst_ip, src_port, dst_port, payload.size());
	endfunction

	constraint payload_size_c {
    if (eth_type == 16'h0806)	
	    payload.size() == 0;
	}

	virtual function int data_create(bit req=0);
	    longint   mac_src;
      longint   mac_dst;
	    longint   dataout[64];
	    longint   ctrlout[64];
	    int       ip_src;
	    int       ip_dst;
	    int       sport;
      int       dport;
	    int       payload_len;
	    int       ret_size;
	    shortint  eth_type_s;
      shortint  op;
	    byte      payload_bytes[];

	    // Map class fields
	    mac_src     = src_addr;
	    mac_dst     = dst_addr;
	    ip_src      = src_ip;
	    ip_dst      = dst_ip;
	    sport       = src_port;
	    dport       = dst_port;
	    payload_len = payload.size();
	    eth_type_s  = eth_type;

		if (req) 
		  op = 1; // ARP request
		else   
		  op = 2; // ARP reply or normal UDP frame

	    // Copy payload
    payload_bytes = new[payload_len];
    foreach (payload[i]) begin
        payload_bytes[i] = payload[i];
    end

    // Call frame creation function
    ret_size = xgmii_eth_frame_c(mac_src, mac_dst, ip_src, ip_dst, eth_type_s,
                            sport, dport, payload_bytes, dataout, ctrlout, op);

		if (ret_size < 2)
			`uvm_error(get_type_name(), "DPI function xgmii_eth_frame_c failed")
		else 
		begin	
			`uvm_info(get_type_name(), "DPI function xgmii_eth_frame_c succeeded", UVM_LOW);
			// Copy output data to class fields
			data_out = new[ret_size];
			ctrl_out = new[ret_size];
			for (int i = 0; i < ret_size; i++) begin
			    data_out[i] = dataout[i];
			    ctrl_out[i] = ctrlout[i];
			end
		end
	    return ret_size;
	endfunction

	virtual function string print_data();
		string s = "\nData Output:\t\t";
		foreach (data_out[i]) begin
			s = {s, $sformatf("%016h ", data_out[i])};
			if (((i+1) % 4) == 0)
				s = {s, "\n                      "};
			// break every 4 words, indent under "Data Output:"
		end
		// s = {s, "\nCtrl Output:\n                      "};
		// foreach (ctrl_out[i]) begin
		// 	s = {s, $sformatf("%02h ", ctrl_out[i])};
		// 	if (((i+1) % 16) == 0)
		// 		s = {s, "\n                      "};
		// 	// break every 16 bytes, indent under "Ctrl Output:"
		// end
		return s;
	endfunction

endclass