class scoreboard extends uvm_scoreboard;
	`uvm_component_utils(scoreboard)

	// Analysis import declarations
	`uvm_analysis_imp_decl(_expected)
	`uvm_analysis_imp_decl(_actual)

	// Analysis implementation ports
	uvm_analysis_imp_expected#(sq_item, scoreboard) in_port;
	uvm_analysis_imp_actual#(sq_item, scoreboard)   out_port;
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
		in_port  = new("in_port", this);
		out_port = new("out_port", this);
		match = 0;
		mis_match = 0;
	endfunction
	virtual function void write_expected(sq_item tr);

	  // Ethernet
	  longint unsigned m_udp_eth_dest_mac, m_udp_eth_src_mac; // 48-bit
	  shortint unsigned m_udp_eth_type;                      // 16-bit
	  // ARP
	  shortint unsigned arp_hwtype, arp_ptype;               // 16-bit
	  byte unsigned arp_hwlen, arp_plen;                     // 8-bit
	  shortint unsigned arp_op;                              // 16-bit
	  
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
	//   `uvm_info("SCOREBOARD_EXPECTED", tr.print_data(), UVM_LOW)
		i = scb_xgmii_to_udp(tr.data_out, tr.ctrl_out,
                               m_udp_eth_dest_mac, m_udp_eth_src_mac, m_udp_eth_type,
                               arp_hwtype, arp_ptype, arp_hwlen, arp_plen, arp_op,
                               m_udp_ip_version, m_udp_ip_ihl, m_udp_ip_dscp, m_udp_ip_ecn,
                               m_udp_ip_length, m_udp_ip_identification, m_udp_ip_flags,
                               m_udp_ip_fragment_offset, m_udp_ip_ttl, m_udp_ip_protocol,
                               m_udp_ip_header_checksum, m_udp_ip_source_ip, m_udp_ip_dest_ip,
                               m_udp_source_port, m_udp_dest_port, m_udp_length, m_udp_checksum,
							   m_udp_payload
							   );
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
		udp_tr.m_udp_payload_data.delete(); // clear old contents

		for (int j = 0; j < i; j++) begin
		    udp_tr.m_udp_payload_data.push_back(tr.data_out[j]);
		end
		if(m_udp_eth_type == 16'h0806) begin
			arp_print(m_udp_eth_dest_mac,m_udp_eth_src_mac,arp_op,m_udp_ip_source_ip,m_udp_ip_dest_ip);
		end
		else if (m_udp_eth_type == 16'h0800) begin
			`uvm_info("SCOREBOARD_EXPECTED", "IP Packet", UVM_LOW)
			`uvm_info("SCOREBOARD_EXPECTED", $sformatf("%s",  udp_tr.convert2string_m_udp()), UVM_LOW)
		end

	endfunction


	// Collect and compare actual transactions
	virtual function void write_actual(sq_item tr);
			`uvm_info("SCOREBOARD_ACTUAL",tr.print_data(), UVM_LOW)
		// tr.print_data();
		// `uvm_info("SCOREBOARD_ACTUAL", 
		//   $sformatf({
		//     "\n----------------------------------------\n",
		//     "   ACTUAL seq_item\n",
		//     "----------------------------------------\n",
		//     "  src_addr : %h\n",
		//     "  dst_addr : %h\n",
		//     "  eth_type : %h\n",
		//     "  src_ip   : %h\n",
		//     "  dst_ip   : %h\n",
		//     "  src_port : %0d\n",
		//     "  dst_port : %0d\n",
		//     "----------------------------------------"
		//   },
		//   tr.src_addr, tr.dst_addr, tr.eth_type,
		//   tr.src_ip, tr.dst_ip, tr.src_port, tr.dst_port),
		//   UVM_LOW
		// );
	endfunction
		
	


	// Report final statistics
	virtual function void report_phase(uvm_phase phase);
		real error_pct = (match + mis_match) ? (100.0 * mis_match / (match + mis_match)) : 0.0;
		`uvm_info("scoreboard_REPORT", $sformatf("Total Matches: %0d, Total Mismatches: %0d, Error Percentage: %.2f%%", match, mis_match, error_pct), UVM_LOW)
	endfunction

	function void arp_print( longint unsigned dst_mac, longint unsigned src_mac, shortint unsigned op,  int unsigned src_ip,  int unsigned dst_ip
);
    string op_str;
    if (op == 16'h0001)
        op_str = "ARP Request";
    else if (op == 16'h0002)
        op_str = "ARP Reply";
    else
        op_str = $sformatf("Unknown (0x%0h)", op);

    `uvm_info("ARP", 
        $sformatf(
            "Ethernet: %012h -> %012h | %s | Src IP: %0d.%0d.%0d.%0d | Dst IP: %0d.%0d.%0d.%0d",
            src_mac, dst_mac, op_str,
            src_ip[31:24], src_ip[23:16], src_ip[15:8], src_ip[7:0],
            dst_ip[31:24], dst_ip[23:16], dst_ip[15:8], dst_ip[7:0]
        ),
        UVM_LOW
    );
endfunction

endclass : scoreboard