class scoreboard extends uvm_scoreboard;
  `uvm_component_utils(scoreboard)

  uvm_get_port#(udp_seq_item)   udp_send;
  uvm_get_port#(xgmii_seq_item) xgmii_send;

  // Queues to hold expected and actual transactions and pending ARP requests
  udp_seq_item        udp_act;
  xgmii_seq_item      xgmii_act, pending, xgmii_expec;
  // ------------------------------------------------------
  // Analysis import declarations
  // ------------------------------------------------------
  `uvm_analysis_imp_decl(_actual_xgmii)
  `uvm_analysis_imp_decl(_actual_udp)
  // ------------------------------------------------------
  // Analysis implementation ports
  // ------------------------------------------------------
  uvm_analysis_imp_actual_xgmii   #(xgmii_seq_item, scoreboard)  xgmii_out_port;

  uvm_analysis_imp_actual_udp     #(udp_seq_item, scoreboard) udp_out_port;
  int match, mis_match , i;

  // Constructor: create imp ports and initialize stats
  function new(string name, uvm_component parent);
    super.new(name, parent);
   endfunction

  // Build phase: nothing additional needed
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // -------- XGMII Ports --------
    xgmii_out_port = new("xgmii_out_port", this);  // actual

    // -------- UDP Ports --------
    udp_out_port   = new("udp_out_port", this);    // actual

    udp_send       = new("udp_send", this);
    xgmii_send     = new("xgmii_send", this);

    // Initialize statistics
    match     = 0;
    mis_match = 0;

    xgmii_expec = xgmii_seq_item::type_id::create("xgmii_expec", this);
  endfunction


  // Collect and compare actual transactions
  virtual function void write_actual_udp(udp_seq_item tr);
    udp_seq_item exp_tr;

    udp_act = tr;
    `uvm_info("SCOREBOARD_ACTUAL", $sformatf("%s", udp_act.convert2string_m_udp()), UVM_HIGH)

    if (udp_send.size() == 0) begin
      `uvm_error("SCOREBOARD_MISMATCH","No expected UDP transaction available for comparison")
      mis_match++;
      return;
    end

    udp_send.try_get(exp_tr);
    `uvm_info("SCOREBOARD_EXPECTED", $sformatf("%s", exp_tr.convert2string_m_udp()), UVM_HIGH)

    if (udp_pkt_compare(tr, exp_tr)) begin
      `uvm_info("SCOREBOARD_MATCH", "Actual UDP transaction matches expected", UVM_LOW)
      match++;
    end else begin
      `uvm_error("SCOREBOARD_MISMATCH", "Actual UDP transaction does not match expected")
      mis_match++;
      `uvm_info("SCOREBOARD_MISMATCH_DETAILS", $sformatf("Expected:\n%s\nActual:\n%s", exp_tr.convert2string_m_udp(), tr.convert2string_m_udp()), UVM_LOW)
    end
  endfunction


  

  virtual function void write_actual_xgmii(xgmii_seq_item tr);
    xgmii_seq_item exp_tr;
    bit correct;
    int checking_size;
    bit checking_start;
    static bit collecting;
    static bit [63:0] data_q[$];
           bit [63:0] data_64_in;
    static bit [7:0]  ctrl_q[$];
           bit [7:0]  ctrl_8_in;
    correct = 1;
    checking_start = 0;
    data_64_in = tr.data_out[0];
    ctrl_8_in  = tr.ctrl_out[0];
    for (int i = 0; i < 8; i++) begin
            byte data_lane = data_64_in[8*i +: 8];
            bit  ctrl_lane = ctrl_8_in[i];

            if (ctrl_lane) begin
              case (data_lane)
                  8'h07: begin
                    `uvm_info("MONITOR_READ", "Received IDLE character", UVM_DEBUG);
                  end
                  8'hFB: begin
                    `uvm_info("MONITOR_READ", "Received START character", UVM_HIGH);
                    collecting = 1;
                    data_q.delete();
                    ctrl_q.delete();
                  end
                  8'hFD: begin
                    `uvm_info("MONITOR_READ", "Received END character", UVM_HIGH);
                    collecting = 0;
                    checking_start = 1;
                    // push the last word
                    data_q.push_back(data_64_in);
                    ctrl_q.push_back(ctrl_8_in);

                    // Build transaction once frame ends
                    xgmii_act = xgmii_seq_item::type_id::create("xgmii_act", this);
                    xgmii_act.data_out = new[data_q.size()];
                    xgmii_act.ctrl_out = new[ctrl_q.size()];
                    for (int j = 0; j < data_q.size(); j++) begin
                      xgmii_act.data_out[j] = data_q[j];
                      xgmii_act.ctrl_out[j] = ctrl_q[j];
                    end
                  end
              endcase
            end
        end

        // Collect payload during active frame
        if (collecting) begin
          data_q.push_back(data_64_in);
          ctrl_q.push_back(ctrl_8_in);
          `uvm_info("MONITOR_READ", $sformatf("Captured tdata: %h", data_64_in), UVM_HIGH);
        end



    if (checking_start) begin
      if (xgmii_send.size() == 0) begin
        `uvm_error("SCOREBOARD_MISMATCH","No expected XGMII transaction available for comparison")
        `uvm_info("SCOREBOARD_MISMATCH_DETAILS", $sformatf("Actual XGMII Packet: \n%s", xgmii_act.print_data()), UVM_LOW)
        mis_match++;
        return;
      end

      `uvm_info("SCOREBOARD_ACTUAL_XGMII", $sformatf("ACTUAL XGMII Packet: \n%s", xgmii_act.print_data()), UVM_MEDIUM)

      exp_tr = xgmii_seq_item::type_id::create("exp_tr", this);
      xgmii_send.try_get(exp_tr);

      `uvm_info("SCOREBOARD_EXPECTED_XGMII", $sformatf("EXPECTED XGMII Packet: \n%s", exp_tr.print_data()), UVM_MEDIUM)

      checking_size = exp_tr.data_out.size() - 2; // ignore last 2 words (IFG)

      correct = xgmii_pkt_compare(exp_tr, xgmii_act, checking_size);

      if (correct) begin
        `uvm_info("SCOREBOARD_MATCH", "Actual XGMII transaction matches expected", UVM_LOW)
        match++;
      end
      else begin
        mis_match++;
        `uvm_info("SCOREBOARD_MISMATCH_DETAILS", $sformatf("Expected:\n%s\nActual:\n%s", exp_tr.print_data(), tr.print_data()), UVM_LOW)
      end
    end
  endfunction




  // Report final statistics
  virtual function void report_phase(uvm_phase phase);
    real error_pct = (match + mis_match) ? (100.0 * mis_match / (match + mis_match)) : 0.0;
    `uvm_info("scoreboard_REPORT", $sformatf("Total Matches: %0d, Total Mismatches: %0d, Error Percentage: %.2f%%", match, mis_match, error_pct), UVM_LOW)
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

  function bit xgmii_pkt_compare(xgmii_seq_item exp_tr, xgmii_seq_item act_tr, int checking_size);
    bit correct = 1;

    // Compare data_out
    if (act_tr.data_out.size() != checking_size) begin
      `uvm_error("SCOREBOARD_MISMATCH",
        $sformatf("data_out size mismatch. Expected=%0d, Actual=%0d",
        checking_size, act_tr.data_out.size()))
      correct = 0;
    end
    else begin
      foreach (act_tr.data_out[i]) begin
        if (act_tr.data_out[i] !== exp_tr.data_out[i]) begin
          `uvm_error("SCOREBOARD_MISMATCH",
            $sformatf("Data mismatch at word[%0d]. Expected=%h, Actual=%h",
            i, exp_tr.data_out[i], act_tr.data_out[i]))
          correct = 0;
        end
      end
    end

    // Compare ctrl_out
    if (act_tr.ctrl_out.size() != checking_size) begin
      `uvm_error("SCOREBOARD_MISMATCH",
        $sformatf("ctrl_out size mismatch. Expected=%0d, Actual=%0d",
        checking_size, act_tr.ctrl_out.size()))
      correct = 0;
    end
    else begin
      foreach (act_tr.ctrl_out[i]) begin
        if (act_tr.ctrl_out[i] !== exp_tr.ctrl_out[i]) begin
          `uvm_error("SCOREBOARD_MISMATCH",
            $sformatf("Ctrl mismatch at byte[%0d]. Expected=%h, Actual=%h",
            i, exp_tr.ctrl_out[i], act_tr.ctrl_out[i]))
          correct = 0;
        end
      end
    end

    return correct;
  endfunction


endclass : scoreboard