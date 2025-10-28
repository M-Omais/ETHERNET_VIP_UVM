class reference_model extends uvm_component;
  `uvm_component_utils(reference_model)

  typedef struct {	//struct for ARP table
    bit [31:0] ip;
    bit [47:0] mac;
    bit        req;
    bit        valid;
  } arp_item_t;

  arp_item_t arp_table[$];

  uvm_put_port#(udp_seq_item)   udp_send;
  uvm_put_port#(xgmii_seq_item) xgmii_send;
  xgmii_seq_item pending;


	`uvm_analysis_imp_decl(_expected_xgmii)
	`uvm_analysis_imp_decl(_expected_udp)
  // Analysis imp to receive transactions
  uvm_analysis_imp_expected_xgmii#(xgmii_seq_item, reference_model) mon_in;
  uvm_analysis_imp_expected_udp#(udp_seq_item, reference_model)     udp_in;

  bit [63:0] data_64_in; 
  bit [63:0] data_final[]; 
  bit [63:0] data_q[$];
  bit [7:0]  ctrl_8_in;
  bit [7:0]  ctrl_final[];
  bit [7:0]  ctrl_q[$];
  bit [7:0]  data_byte;
  bit        ctrl_bit;
  bit        start;

  // Output analysis port to send expected results to scoreboard
  uvm_analysis_port#(udp_seq_item) ref_out;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    start = 0;
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mon_in      = new("mon_in",     this);
    udp_in      = new("udp_in",     this);
    ref_out     = new("ref_out",    this);
    udp_send    = new("udp_send",   this);
    xgmii_send  = new("xgmii_send", this);
    pending     = xgmii_seq_item::type_id::create("pending", this);
  endfunction

  // This is automatically called when monitor writes a transaction
  function void write_expected_xgmii(xgmii_seq_item tr);
    // `uvm_info("REF_MODEL", $sformatf("Received transaction: %s", tr.convert2string()), UVM_LOW)

    // Copy data fields
    data_64_in = tr.data_out[0];
    ctrl_8_in  = tr.ctrl_out[0];

    // Iterate over each XGMII lane
    for (int i = 0; i < 8; i++) begin
      data_byte = data_64_in[8*i +: 8];
      ctrl_bit  = ctrl_8_in[i];

      if (ctrl_bit) begin
        case (data_byte)
          8'h07: begin
            `uvm_info("REF_MODEL", "Received IDLE character", UVM_DEBUG);
          end

          8'hFB: begin
            `uvm_info("REF_MODEL", "Received START character", UVM_HIGH);
            start = 1;
            data_q.delete();
            ctrl_q.delete();
          end

          8'hFD: begin
            `uvm_info("REF_MODEL", "Received END character", UVM_HIGH);
            start = 0;

            // Push last captured data
            data_q.push_back(data_64_in);
            ctrl_q.push_back(ctrl_8_in);

            // Create new XGMII transaction per frame
            data_final = new[data_q.size()];
            ctrl_final = new[ctrl_q.size()];

            for (int j = 0; j < data_q.size(); j++) begin
              data_final[j] = data_q[j];
              ctrl_final[j] = ctrl_q[j];
            end
            // printing captured frame
            // `uvm_info("REF_MODEL", $sformatf("Captured XGMII Frame: %s", frame_tr.print_data()), UVM_LOW);
            process_xgmii_frame(data_final, ctrl_final);

            // -----------------------------
            // Translate XGMII → UDP fields
            // -----------------------------
            

          end // case END (8'hFD)
        endcase
      end
       
    end // for each lane
    if (start) begin
        // Inside frame: collect data and ctrl
        data_q.push_back(data_64_in);
        ctrl_q.push_back(ctrl_8_in);
    end
  endfunction

  function void process_xgmii_frame(bit [63:0] data_final[], bit [7:0] ctrl_final[]);

    // -----------------------------
    // Local variables for decoding
    // -----------------------------
    //---- ETH ----
    longint unsigned  m_udp_eth_dest_mac;
    longint unsigned  m_udp_eth_src_mac;
    shortint unsigned m_udp_eth_type;
    //---- ARP ----
    shortint unsigned arp_hwtype;
    shortint unsigned arp_ptype;
    byte unsigned     arp_hwlen;
    byte unsigned     arp_plen;
    shortint unsigned arp_op;
    //---- IP ----
    byte unsigned     m_udp_ip_version;
    byte unsigned     m_udp_ip_ihl;
    byte unsigned     m_udp_ip_dscp;
    byte unsigned     m_udp_ip_ecn;
    shortint unsigned m_udp_ip_length;
    shortint unsigned m_udp_ip_identification;
    byte unsigned     m_udp_ip_flags;
    byte unsigned     m_udp_ip_ttl;
    byte unsigned     m_udp_ip_protocol;
    shortint unsigned m_udp_ip_fragment_offset;
    shortint unsigned m_udp_ip_header_checksum;
    int unsigned      m_udp_ip_source_ip;
    int unsigned      m_udp_ip_dest_ip;
    // ---- UDP ----
    shortint unsigned m_udp_source_port;
    shortint unsigned m_udp_dest_port;
    shortint unsigned m_udp_length;
    shortint unsigned m_udp_checksum;
    bit [63:0]        m_udp_payload[1500];

    udp_seq_item      udp_tr;
    xgmii_seq_item    temp;
    int               r_size;

    udp_tr = udp_seq_item::type_id::create("udp_tr");
    temp = xgmii_seq_item::type_id::create("xgmii_tr");

    // -----------------------------------
    // Translate XGMII frame to UDP fields
    // -----------------------------------
    r_size = scb_xgmii_to_udp(data_final, ctrl_final, m_udp_eth_dest_mac, m_udp_eth_src_mac, m_udp_eth_type,
                              arp_hwtype, arp_ptype, arp_hwlen, arp_plen, arp_op,m_udp_ip_version,
                              m_udp_ip_ihl, m_udp_ip_dscp, m_udp_ip_ecn, m_udp_ip_length,
                              m_udp_ip_identification, m_udp_ip_flags,m_udp_ip_fragment_offset, m_udp_ip_ttl,
                              m_udp_ip_protocol, m_udp_ip_header_checksum, m_udp_ip_source_ip, m_udp_ip_dest_ip,
                              m_udp_source_port, m_udp_dest_port, m_udp_length, m_udp_checksum, m_udp_payload
    );

    // --------------------------
    // Populate UDP transaction
    // --------------------------
    udp_tr.m_udp_eth_src_mac          = m_udp_eth_src_mac;
    udp_tr.m_udp_eth_dest_mac         = m_udp_eth_dest_mac;
    udp_tr.m_udp_eth_type             = m_udp_eth_type;
    udp_tr.m_udp_ip_version           = m_udp_ip_version;
    udp_tr.m_udp_ip_ihl               = m_udp_ip_ihl;
    udp_tr.m_udp_ip_dscp              = m_udp_ip_dscp;
    udp_tr.m_udp_ip_ecn               = m_udp_ip_ecn;
    udp_tr.m_udp_ip_length            = m_udp_ip_length;
    udp_tr.m_udp_ip_identification    = m_udp_ip_identification;
    udp_tr.m_udp_ip_flags             = m_udp_ip_flags;
    udp_tr.m_udp_ip_fragment_offset   = m_udp_ip_fragment_offset;
    udp_tr.m_udp_ip_ttl               = m_udp_ip_ttl;
    udp_tr.m_udp_ip_protocol          = m_udp_ip_protocol;
    udp_tr.m_udp_ip_header_checksum   = m_udp_ip_header_checksum;
    udp_tr.m_udp_ip_source_ip         = m_udp_ip_source_ip;
    udp_tr.m_udp_ip_dest_ip           = m_udp_ip_dest_ip;
    udp_tr.m_udp_source_port          = m_udp_source_port;
    udp_tr.m_udp_dest_port            = m_udp_dest_port;
    udp_tr.m_udp_length               = m_udp_length;
    udp_tr.m_udp_checksum             = m_udp_checksum;

    // ---------------------------
    // Handle ARP or UDP packets
    // ---------------------------
    if (m_udp_eth_type == 16'h0806) begin
      // === ARP packet handling ===
      foreach (arp_table[i]) begin
        if (arp_table[i].req && arp_table[i].ip == m_udp_ip_source_ip) begin
          arp_table[i].valid = 1;
          arp_table[i].mac   = m_udp_eth_src_mac;
          temp = pending;
          if (temp.dst_addr == {48{1'b1}} && temp.dst_ip == m_udp_ip_source_ip) begin
            temp.dst_addr = m_udp_eth_src_mac;
            data_create(temp);
            xgmii_send.try_put(temp);
          end
          `uvm_info("SCOREBOARD_EXPECTED", $sformatf("ARP Cache Update: IP %s -> MAC %012h",
                    ip_to_string(m_udp_ip_source_ip), m_udp_eth_src_mac), UVM_LOW)
          break;
        end
      end

      arp_print(m_udp_eth_dest_mac, m_udp_eth_src_mac, arp_op, m_udp_ip_source_ip, m_udp_ip_dest_ip);
    end

    else if (m_udp_eth_type == 16'h0800) begin
      // === IPv4 UDP Packet ===
      udp_tr.m_udp_payload_data.delete();

      for (int j = 0; j < (m_udp_length - 8)/8; j++) begin
        udp_tr.m_udp_payload_data.push_back(m_udp_payload[j]);
        `uvm_info("SCOREBOARD_EXPECTED", $sformatf("Payload[%0d]: %h", j, m_udp_payload[j]), UVM_DEBUG);
      end

      `uvm_info("SCOREBOARD_EXPECTED", $sformatf("%s", udp_tr.convert2string_m_udp()), UVM_LOW);

      // Send expected UDP transaction to scoreboard
      udp_send.try_put(udp_tr);
    end

  endfunction

  function void write_expected_udp(udp_seq_item tr);
    // `uvm_info("REF_MODEL", $sformatf("Received UDP transaction: %s", tr.convert2string_s_udp()), UVM_LOW)
    xgmii_seq_item expec;
		bit            found;
		int            idx;
    int            ret_size;

    found = 0;
    idx = 0;

		`uvm_info("SCOREBOARD_EXPECTED_UDP", $sformatf("INCOMING UDP Packet:\n%s", tr.convert2string_s_udp()), UVM_LOW)

		expec          = xgmii_seq_item::type_id::create("expec", this);
		expec.src_addr = dut_mac;
		expec.src_ip   = tr.s_udp_ip_source_ip;
		expec.dst_ip   = tr.s_udp_ip_dest_ip;
		expec.src_port = tr.s_udp_source_port;
		expec.dst_port = tr.s_udp_dest_port;

		// Default: no valid ARP mapping found
		foreach (arp_table[i]) begin
			// Check for valid ARP entry throughout table
			if (arp_table[i].ip == tr.s_udp_ip_dest_ip && arp_table[i].valid) begin
				expec.dst_addr = arp_table[i].mac;
				expec.payload = new[tr.s_udp_payload_data.size() * 8];
				expec.eth_type = 16'h0800;
				foreach (tr.s_udp_payload_data[i]) begin
					for (int b = 0; b < 8; b++) begin
						expec.payload[idx] = tr.s_udp_payload_data[i][8*b +: 8];
						`uvm_info("SCOREBOARD_EXPECTED_UDP", $sformatf("Flattened Payload[%0d]: %h", idx, expec.payload[idx]), UVM_DEBUG);
						idx++;
					end
				end
				ret_size = data_create(expec);
				// Flatten payload
				xgmii_send.try_put(expec);
				found = 1;
				`uvm_info("SCOREBOARD_EXPECTED_UDP", $sformatf("Resolved IP %sto MAC %012h",ip_to_string(tr.s_udp_ip_dest_ip), arp_table[i].mac), UVM_MEDIUM)
				break;
			end
		end

		if (!found) begin
			expec.eth_type = 16'h0806; // ARP
			// expec.dst_addr =  {48{1'b1}};
			`uvm_info("SCOREBOARD_EXPECTED_UDP", $sformatf("No ARP entry for IP %s -> sending ARP", ip_to_string(tr.s_udp_ip_dest_ip)), UVM_LOW)
			arp_table.push_back('{ip: tr.s_udp_ip_dest_ip, mac: 48'h0, req: 1'b1, valid: 1'b0}); // add ARP request entry
			idx = data_create(expec,1);
			xgmii_send.try_put(expec);// send ARP request
			// Create pending XGMII packet for later UDP send after ARP reply
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
    end
  endfunction

endclass
