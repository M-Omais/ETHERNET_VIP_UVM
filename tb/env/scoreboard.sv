class scoreboard extends uvm_scoreboard;
	`uvm_component_utils(scoreboard)

	typedef struct {	//struct for ARP table
		bit [31:0] ip;
		bit [47:0] mac;
		bit        req;
		bit        valid;
	} arp_item_t;
	arp_item_t arp_table[$];
	udp_seq_item udp_exp[$], udp_act;
	sq_item     xgmii_exp[$], xgmii_act,pending;
	// ------------------------------------------------------
	// Analysis import declarations
	// ------------------------------------------------------
	`uvm_analysis_imp_decl(_expected_xgmii)
	`uvm_analysis_imp_decl(_actual_xgmii)
	`uvm_analysis_imp_decl(_expected_udp)
	`uvm_analysis_imp_decl(_actual_udp)
	// ------------------------------------------------------
	// Analysis implementation ports
	// ------------------------------------------------------
	uvm_analysis_imp_expected_udp #(sq_item, scoreboard)  xgmii_in_port;
	uvm_analysis_imp_actual_xgmii   #(sq_item, scoreboard)  xgmii_out_port;

	uvm_analysis_imp_expected_xgmii   #(udp_seq_item, scoreboard) udp_in_port;
	uvm_analysis_imp_actual_udp     #(udp_seq_item, scoreboard) udp_out_port;
	int match, mis_match , i;

	// Constructor: create imp ports and initialize stats
	function new(string name, uvm_component parent);
		super.new(name, parent);
		match = 0;
		mis_match = 0;
	endfunction

	// Build phase: nothing additional needed
	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);

		// -------- XGMII Ports --------
		xgmii_in_port  = new("xgmii_in_port", this);   // expected
		xgmii_out_port = new("xgmii_out_port", this);  // actual

		// -------- UDP Ports --------
		udp_in_port    = new("udp_in_port", this);     // expected
		udp_out_port   = new("udp_out_port", this);    // actual

		match     = 0;
		mis_match = 0;
	endfunction

	virtual function void write_expected_udp(sq_item tr);

		// Ethernet
		longint unsigned m_udp_eth_dest_mac, m_udp_eth_src_mac; 
		shortint unsigned m_udp_eth_type;                      
		// ARP
		shortint unsigned arp_hwtype, arp_ptype;               
		byte unsigned arp_hwlen, arp_plen;                     
		shortint unsigned arp_op;                              
		// IP
		byte unsigned m_udp_ip_version, m_udp_ip_ihl, m_udp_ip_dscp, m_udp_ip_ecn;
		shortint unsigned m_udp_ip_length, m_udp_ip_identification;
		byte unsigned m_udp_ip_flags, m_udp_ip_ttl, m_udp_ip_protocol;
		shortint unsigned m_udp_ip_fragment_offset, m_udp_ip_header_checksum;
		int unsigned m_udp_ip_source_ip, m_udp_ip_dest_ip;
		// UDP
		shortint unsigned m_udp_source_port, m_udp_dest_port, m_udp_length, m_udp_checksum;
		// payload data
		bit [63:0] m_udp_payload[1500];     // payload data
		udp_seq_item udp_tr = udp_seq_item::type_id::create("udp_tr");
		sq_item temp = sq_item::type_id::create("xgmii_tr");
		//   `uvm_info("SCOREBOARD_EXPECTED", tr.print_data(), UVM_LOW)
		i = scb_xgmii_to_udp(tr.data_out, {tr.ctrl_out}, m_udp_eth_dest_mac, m_udp_eth_src_mac, m_udp_eth_type,
							arp_hwtype, arp_ptype, arp_hwlen, arp_plen, arp_op, m_udp_ip_version,
							m_udp_ip_ihl, m_udp_ip_dscp, m_udp_ip_ecn,m_udp_ip_length, m_udp_ip_identification,
							m_udp_ip_flags, m_udp_ip_fragment_offset,m_udp_ip_ttl, m_udp_ip_protocol,
							m_udp_ip_header_checksum, m_udp_ip_source_ip, m_udp_ip_dest_ip, m_udp_source_port,
							m_udp_dest_port, m_udp_length, m_udp_checksum, m_udp_payload);

			udp_tr.m_udp_eth_src_mac = m_udp_eth_src_mac;
			udp_tr.m_udp_eth_dest_mac = m_udp_eth_dest_mac;
			udp_tr.m_udp_eth_type = m_udp_eth_type;
			udp_tr.m_udp_ip_version = m_udp_ip_version;
			udp_tr.m_udp_ip_ihl = m_udp_ip_ihl;
			udp_tr.m_udp_ip_dscp = m_udp_ip_dscp;
			udp_tr.m_udp_ip_ecn = m_udp_ip_ecn;
			udp_tr.m_udp_ip_length = m_udp_ip_length;
			udp_tr.m_udp_ip_identification = m_udp_ip_identification;
			udp_tr.m_udp_ip_flags = m_udp_ip_flags;
			udp_tr.m_udp_ip_fragment_offset = m_udp_ip_fragment_offset;
			udp_tr.m_udp_ip_ttl = m_udp_ip_ttl;
			udp_tr.m_udp_ip_protocol = m_udp_ip_protocol;
			udp_tr.m_udp_ip_header_checksum = m_udp_ip_header_checksum;
			udp_tr.m_udp_ip_source_ip = m_udp_ip_source_ip;
			udp_tr.m_udp_ip_dest_ip = m_udp_ip_dest_ip;
			udp_tr.m_udp_source_port = m_udp_source_port;
			udp_tr.m_udp_dest_port = m_udp_dest_port;
			udp_tr.m_udp_length = m_udp_length;
			udp_tr.m_udp_checksum = m_udp_checksum;
		// copying the payload

		
		if (m_udp_eth_type == 16'h0806) begin

			// Search for existing ARP entry
			foreach (arp_table[i]) begin
				if (arp_table[i].req == 1'b1 && arp_table[i].ip == m_udp_ip_source_ip) begin
					arp_table[i].valid = 1; // request seen
					arp_table[i].mac = m_udp_eth_src_mac;
					temp =xgmii_exp.pop_front();
					if (temp.dst_addr ==  {48{1'b1}} && temp.dst_ip == m_udp_ip_source_ip) begin
						temp.dst_addr = m_udp_eth_src_mac;
						temp.data_create();
						xgmii_exp.push_back(temp);

					end
					`uvm_info("SCOREBOARD_EXPECTED", $sformatf("ARP Cache Update: IP %s -> MAC %012h", ip_to_string(m_udp_ip_source_ip), m_udp_eth_src_mac), UVM_MEDIUM)
					break;
				end
			end

			arp_print(m_udp_eth_dest_mac, m_udp_eth_src_mac, arp_op, m_udp_ip_source_ip, m_udp_ip_dest_ip);
		end

		else if (m_udp_eth_type == 16'h0800) begin
			udp_tr.m_udp_payload_data.delete(); // clear old contents

			for (int j = 0; j < (m_udp_length-8)/8 ; j++)	begin
				udp_tr.m_udp_payload_data.push_back(m_udp_payload[j]);
				`uvm_info("SCOREBOARD_EXPECTED", $sformatf("Length %0d Payload[%0d]: %h", (m_udp_length-8)/8, j, m_udp_payload[j]), UVM_DEBUG);	
			end	
			`uvm_info("SCOREBOARD_EXPECTED", $sformatf("%s",  udp_tr.convert2string_m_udp()), UVM_LOW)
			udp_exp.push_back(udp_tr);
		end

	endfunction


	// Collect and compare actual transactions
	virtual function void write_actual_udp(udp_seq_item tr);
		udp_seq_item exp_tr;

		udp_act = tr;
		`uvm_info("SCOREBOARD_ACTUAL", $sformatf("%s", udp_act.convert2string_m_udp()), UVM_LOW)

		if (udp_exp.size() == 0) begin
		`uvm_error("SCOREBOARD_MISMATCH","No expected UDP transaction available for comparison")
		mis_match++;
		return;
		end

		exp_tr = udp_exp.pop_front();
		`uvm_info("SCOREBOARD_EXPECTED", $sformatf("%s", exp_tr.convert2string_m_udp()), UVM_LOW)

		if (udp_pkt_compare(tr, exp_tr)) begin
			`uvm_info("SCOREBOARD_MATCH", "Actual UDP transaction matches expected", UVM_LOW)
			match++;
		end else begin
			`uvm_error("SCOREBOARD_MISMATCH", "Actual UDP transaction does not match expected")
			mis_match++;
			`uvm_info("SCOREBOARD_MISMATCH_DETAILS", $sformatf("Expected:\n%s\nActual:\n%s", exp_tr.convert2string_m_udp(), tr.convert2string_m_udp()), UVM_LOW)
		end
	endfunction


	virtual function void write_expected_xgmii(udp_seq_item tr);
		sq_item expec;
		bit found = 0;
		int idx = 0;
		`uvm_info("SCOREBOARD_EXPECTED_UDP", $sformatf("INCOMING UDP Packet:\n%s", tr.convert2string_s_udp()), UVM_LOW)

		expec = sq_item::type_id::create("expec", this);
		expec.src_addr = dut_mac;
		expec.src_ip   = tr.s_udp_ip_source_ip;
		expec.dst_ip   = tr.s_udp_ip_dest_ip;
		expec.src_port = tr.s_udp_source_port;
		expec.dst_port = tr.s_udp_dest_port;
		// Default: no valid ARP mapping found
		foreach (arp_table[i]) begin
			if (arp_table[i].ip == tr.s_udp_ip_dest_ip && arp_table[i].valid) begin
				expec.dst_addr = arp_table[i].mac;
				expec.payload = new[tr.s_udp_payload_data.size()*8];
				expec.eth_type = 16'h0800;
				foreach (tr.s_udp_payload_data[i]) begin
					for (int b = 0; b < 8; b++) begin
						expec.payload[idx] = tr.s_udp_payload_data[i][8*b +: 8];
						`uvm_info("SCOREBOARD_EXPECTED_UDP", $sformatf("Flattened Payload[%0d]: %h", idx, expec.payload[idx]), UVM_DEBUG);
						idx++;
					end
				end
				idx = expec.data_create();
				// Flatten payload
				xgmii_exp.push_back(expec);
				found = 1;
				`uvm_info("SCOREBOARD_EXPECTED_UDP", $sformatf("Resolved IP %sto MAC %012h",ip_to_string(tr.s_udp_ip_dest_ip), arp_table[i].mac), UVM_MEDIUM)
				break;
			end
		end

		if (!found) begin
			expec.eth_type = 16'h0806; // ARP
			// expec.dst_addr =  {48{1'b1}};
			`uvm_info("SCOREBOARD_EXPECTED_UDP", 
			$sformatf("No ARP entry for IP %s -> sending ARP", ip_to_string(tr.s_udp_ip_dest_ip)), UVM_LOW)
			arp_table.push_back('{ip: tr.s_udp_ip_dest_ip, mac: 48'h0, req: 1'b1, valid: 1'b0});
			idx = expec.data_create(1);
			xgmii_exp.push_back(expec);
			pending = sq_item::type_id::create("pending", this);
			pending.src_addr = dut_mac;
			pending.dst_addr = {48{1'b1}}; // Broadcast
			pending.src_ip   = tr.s_udp_ip_source_ip;
			pending.dst_ip   = tr.s_udp_ip_dest_ip;
			pending.src_port = tr.s_udp_source_port;
			pending.dst_port = tr.s_udp_dest_port;
			pending.payload = new[tr.s_udp_payload_data.size()*8];
			pending.eth_type = 16'h0800;
			idx=0;
			foreach (tr.s_udp_payload_data[i]) begin
				for (int b = 0; b < 8; b++) begin
					pending.payload[idx] = tr.s_udp_payload_data[i][8*b +: 8];
					`uvm_info("SCOREBOARD_EXPECTED_UDP", $sformatf("Flattened Payload[%0d]: %h", idx, pending.payload[idx]), UVM_DEBUG);
					idx++;
				end
			end
			`uvm_info("SCOREBOARD_EXPECTED_UDP", $sformatf("PENDING XGMII Packet: \n%s", pending.print_data()), UVM_HIGH)
			// Flatten payload
			xgmii_exp.push_back(pending);
		end

		// pending.print_data();
		`uvm_info("SCOREBOARD_EXPECTED_UDP", $sformatf("EXPECTED XGMII Packet: \n%s", expec.print_data()), UVM_LOW)
	endfunction

	virtual function void write_actual_xgmii(sq_item tr);
		sq_item exp_tr;
		bit correct = 1;
		int checking_size;
		if (xgmii_exp.size() == 0) begin
			`uvm_error("SCOREBOARD_MISMATCH","No expected XGMII transaction available for comparison")
			`uvm_info("SCOREBOARD_MISMATCH_DETAILS", $sformatf("Actual XGMII Packet: \n%s", tr.print_data()), UVM_LOW)
			mis_match++;
			return;
		end

		xgmii_act = tr;
		`uvm_info("SCOREBOARD_ACTUAL_XGMII", $sformatf("ACTUAL XGMII Packet: \n%s", xgmii_act.print_data()), UVM_LOW)

		exp_tr = xgmii_exp.pop_front();
		`uvm_info("SCOREBOARD_EXPECTED_XGMII", $sformatf("EXPECTED XGMII Packet: \n%s", exp_tr.print_data()), UVM_LOW)
		checking_size = exp_tr.data_out.size()-2; // ignore last 2 words (IFG)
		// Compare data_out and ctrl_out element by element
		if (xgmii_act.data_out.size() != checking_size) begin
			`uvm_error("SCOREBOARD_MISMATCH", $sformatf("data_out size mismatch. Expected=%0d, Actual=%0d",
			checking_size, xgmii_act.data_out.size()))
			correct = 0;
		end 
		else begin
			foreach (xgmii_act.data_out[i]) begin
				if (xgmii_act.data_out[i] !== exp_tr.data_out[i]) begin
					`uvm_error("SCOREBOARD_MISMATCH", $sformatf("Data mismatch at word[%0d]. Expected=%h, Actual=%h",
					i, exp_tr.data_out[i], xgmii_act.data_out[i]))
					correct = 0;
				end
			end
		end

		if (xgmii_act.ctrl_out.size() != checking_size) begin
			`uvm_error("SCOREBOARD_MISMATCH", $sformatf("ctrl_out size mismatch. Expected=%0d, Actual=%0d",
			checking_size, xgmii_act.ctrl_out.size()))
			correct = 0;
		end 
		else begin
			foreach (xgmii_act.ctrl_out[i]) begin
				if (xgmii_act.ctrl_out[i] !== exp_tr.ctrl_out[i]) begin
					`uvm_error("SCOREBOARD_MISMATCH", $sformatf("Ctrl mismatch at byte[%0d]. Expected=%h, Actual=%h",
					i, exp_tr.ctrl_out[i], xgmii_act.ctrl_out[i]))
					correct = 0;
				end
			end
		end

		if (correct) begin
			`uvm_info("SCOREBOARD_MATCH", "Actual XGMII transaction matches expected", UVM_LOW)
			match++;
		end 
		else begin
			mis_match++;
			`uvm_info("SCOREBOARD_MISMATCH_DETAILS", $sformatf("Expected:\n%s\nActual:\n%s", exp_tr.print_data(), tr.print_data()), UVM_LOW)
		end
	endfunction



	// Report final statistics
	virtual function void report_phase(uvm_phase phase);
		real error_pct = (match + mis_match) ? (100.0 * mis_match / (match + mis_match)) : 0.0;
		`uvm_info("scoreboard_REPORT", $sformatf("Total Matches: %0d, Total Mismatches: %0d, Error Percentage: %.2f%%", match, mis_match, error_pct), UVM_LOW)
	endfunction

	function void arp_print(longint unsigned dst_mac, longint unsigned src_mac, shortint unsigned op,  int unsigned src_ip,  int unsigned dst_ip);
		string op_str;
		if (op == 16'h0001)	op_str = "ARP Request";
		else if (op == 16'h0002) op_str = "ARP Reply";
		else op_str = $sformatf("Unknown (0x%0h)", op);

		`uvm_info("ARP", $sformatf("Ethernet: %012h -> %012h | %s | Src IP: %0d.%0d.%0d.%0d | Dst IP: %0d.%0d.%0d.%0d", src_mac, dst_mac, op_str,
		 src_ip[31:24], src_ip[23:16], src_ip[15:8], src_ip[7:0], dst_ip[31:24], dst_ip[23:16], dst_ip[15:8], dst_ip[7:0]),UVM_LOW);
	endfunction

	
    function bit udp_pkt_compare(udp_seq_item act, udp_seq_item exp);
		bit status = 1; // assume match

		// Ethernet header
		if (act.m_udp_eth_dest_mac !== exp.m_udp_eth_dest_mac) begin
			`uvm_error("PKT_CMP", $sformatf("Dest MAC mismatch: ACT=%012h EXP=%012h",
			act.m_udp_eth_dest_mac, exp.m_udp_eth_dest_mac))
			status = 0;
		end
		if (act.m_udp_eth_src_mac !== exp.m_udp_eth_src_mac) begin
			`uvm_error("PKT_CMP", $sformatf("Src MAC mismatch: ACT=%012h EXP=%012h",
			act.m_udp_eth_src_mac, exp.m_udp_eth_src_mac))
			status = 0;
		end
		if (act.m_udp_eth_type !== exp.m_udp_eth_type) begin
			`uvm_error("PKT_CMP", $sformatf("EthType mismatch: ACT=%04h EXP=%04h",
			act.m_udp_eth_type, exp.m_udp_eth_type))
			status = 0;
		end

		// IP header
		if (act.m_udp_ip_version !== exp.m_udp_ip_version)begin
			`uvm_error("PKT_CMP", $sformatf("IP Version mismatch: ACT=%0d EXP=%0d",
			act.m_udp_ip_version, exp.m_udp_ip_version))
			status = 0;
		end
		if (act.m_udp_ip_ihl !== exp.m_udp_ip_ihl)begin
			`uvm_error("PKT_CMP", $sformatf("IHL mismatch: ACT=%0d EXP=%0d",
			act.m_udp_ip_ihl, exp.m_udp_ip_ihl))
			status = 0;
		end
		if (act.m_udp_ip_dscp !== exp.m_udp_ip_dscp)begin
			`uvm_error("PKT_CMP", $sformatf("DSCP mismatch: ACT=%0d EXP=%0d",
			act.m_udp_ip_dscp, exp.m_udp_ip_dscp))
			status = 0;
		end
		if (act.m_udp_ip_ecn !== exp.m_udp_ip_ecn)begin
			`uvm_error("PKT_CMP", $sformatf("ECN mismatch: ACT=%0d EXP=%0d",
			act.m_udp_ip_ecn, exp.m_udp_ip_ecn))
			status = 0;
		end
		if (act.m_udp_ip_length !== exp.m_udp_ip_length)begin
			`uvm_error("PKT_CMP", $sformatf("IP Length mismatch: ACT=%0d EXP=%0d",
			act.m_udp_ip_length, exp.m_udp_ip_length))
			status = 0;
		end
		if (act.m_udp_ip_identification !== exp.m_udp_ip_identification)begin
			`uvm_error("PKT_CMP", $sformatf("Identification mismatch: ACT=%0d EXP=%0d",
			act.m_udp_ip_identification, exp.m_udp_ip_identification))
			status = 0;
		end
		if (act.m_udp_ip_flags !== exp.m_udp_ip_flags)begin
			`uvm_error("PKT_CMP", $sformatf("Flags mismatch: ACT=%0d EXP=%0d",
			act.m_udp_ip_flags, exp.m_udp_ip_flags))
			status = 0;
		end
		if (act.m_udp_ip_fragment_offset !== exp.m_udp_ip_fragment_offset)begin
			`uvm_error("PKT_CMP", $sformatf("Frag Offset mismatch: ACT=%0d EXP=%0d",
			act.m_udp_ip_fragment_offset, exp.m_udp_ip_fragment_offset))
			status = 0;
		end
		if (act.m_udp_ip_ttl !== exp.m_udp_ip_ttl)begin
			`uvm_error("PKT_CMP", $sformatf("TTL mismatch: ACT=%0d EXP=%0d",
			act.m_udp_ip_ttl, exp.m_udp_ip_ttl))
			status = 0;
		end
		if (act.m_udp_ip_protocol !== exp.m_udp_ip_protocol)begin
			`uvm_error("PKT_CMP", $sformatf("Protocol mismatch: ACT=%0d EXP=%0d",
			act.m_udp_ip_protocol, exp.m_udp_ip_protocol))
			status = 0;
		end
		if (act.m_udp_ip_header_checksum !== exp.m_udp_ip_header_checksum)begin
			`uvm_error("PKT_CMP", $sformatf("Checksum mismatch: ACT=%0h EXP=%0h",
			act.m_udp_ip_header_checksum, exp.m_udp_ip_header_checksum))
			status = 0;
		end
		if (act.m_udp_ip_source_ip !== exp.m_udp_ip_source_ip)begin
			`uvm_error("PKT_CMP", $sformatf("Src IP mismatch: ACT=%0h EXP=%0h",
			act.m_udp_ip_source_ip, exp.m_udp_ip_source_ip))
			status = 0;
		end
		if (act.m_udp_ip_dest_ip !== exp.m_udp_ip_dest_ip)begin
			`uvm_error("PKT_CMP", $sformatf("Dst IP mismatch: ACT=%0h EXP=%0h",
			act.m_udp_ip_dest_ip, exp.m_udp_ip_dest_ip))
			status = 0;
		end
		// UDP header
		if (act.m_udp_source_port !== exp.m_udp_source_port)begin
			`uvm_error("PKT_CMP", $sformatf("UDP Src Port mismatch: ACT=%0d EXP=%0d",
			act.m_udp_source_port, exp.m_udp_source_port))
			status = 0;
		end
		if (act.m_udp_dest_port !== exp.m_udp_dest_port)begin
			`uvm_error("PKT_CMP", $sformatf("UDP Dst Port mismatch: ACT=%0d EXP=%0d",
			act.m_udp_dest_port, exp.m_udp_dest_port))
			status = 0;
		end
		if (act.m_udp_length !== exp.m_udp_length)begin
			`uvm_error("PKT_CMP", $sformatf("UDP Length mismatch: ACT=%0d EXP=%0d",
			act.m_udp_length, exp.m_udp_length))
			status = 0;
		end
		if (act.m_udp_checksum !== exp.m_udp_checksum)begin
			`uvm_error("PKT_CMP", $sformatf("UDP Checksum mismatch: ACT=%0h EXP=%0h",
			act.m_udp_checksum, exp.m_udp_checksum))
			status = 0;
		end
		// Payload
		if (act.m_udp_payload_data.size() != exp.m_udp_payload_data.size()) begin
			`uvm_error("PKT_CMP", $sformatf("Payload size mismatch: ACT=%0d EXP=%0d",
			act.m_udp_payload_data.size(), exp.m_udp_payload_data.size()))
			status = 0;
		end 
		else begin
			foreach (act.m_udp_payload_data[i]) begin
				if (act.m_udp_payload_data[i] !== exp.m_udp_payload_data[i]) begin
					`uvm_error("PKT_CMP", $sformatf("Payload mismatch at index %0d: ACT=%0h EXP=%0h",
					i, act.m_udp_payload_data[i], exp.m_udp_payload_data[i]))
					status = 0;
				end
			end
		end

		return status;
	endfunction


endclass : scoreboard