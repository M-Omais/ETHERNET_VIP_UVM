// Monitor is a passive component that observes DUT signals via virtual interface (vif)
// and converts them into transactions, which are sent out via analysis port to scoreboard, coverage,

class udp_monitor extends uvm_monitor;

  `uvm_component_utils(udp_monitor)  // Factory registration

  virtual udp_if vif;   // Virtual interface to DUT signals

  // Analysis port (sends observed transactions to subscribers: scoreboard, coverage, etc.)
  uvm_analysis_port #(udp_seq_item) ap;

  // Constructor
  function new(string name = "udp_monitor", uvm_component parent = null);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  // Build phase → get virtual interface
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual udp_if)::get(this,"","udp_vif",vif)) begin
      `uvm_fatal("NO_VIF", $sformatf("virtual interface not set for: %s.vif", get_full_name()))
    end
  endfunction

  // Run phase → capture DUT activity
  task run_phase(uvm_phase phase);
    udp_seq_item tr;

    forever begin
      // Wait until DUT asserts valid & ready on header
      @(posedge vif.clk iff (vif.m_udp_hdr_valid && vif.m_udp_hdr_ready));

      tr = udp_seq_item::type_id::create("tr");

      // Capture header fields
      tr.ip_dscp        = vif.m_udp_ip_dscp;
      tr.ip_ecn         = vif.m_udp_ip_ecn;
      tr.ip_ttl         = vif.m_udp_ip_ttl;
      tr.ip_source_ip   = vif.m_udp_ip_source_ip;
      tr.ip_dest_ip     = vif.m_udp_ip_dest_ip;
      tr.udp_source_port= vif.m_udp_source_port;
      tr.udp_dest_port  = vif.m_udp_dest_port;
      tr.udp_length     = vif.m_udp_length;
      tr.udp_checksum   = vif.m_udp_checksum;

      // Capture payload byte by byte
      tr.payload_data.delete(); // clear dynamic array
      do begin
        @(posedge vif.clk iff (vif.m_udp_payload_axis_tvalid && vif.m_udp_payload_axis_tready));
        tr.payload_data.push_back(vif.m_udp_payload_axis_tdata);
      end while (!vif.m_udp_payload_axis_tlast);

      // Optional: capture sideband
      tr.payload_user = vif.m_udp_payload_axis_tuser;
      tr.payload_last = vif.m_udp_payload_axis_tlast;

      // Send out the collected transaction
      `uvm_info("MONITOR", tr.convert2string(), UVM_LOW)
      ap.write(tr);
    end
  endtask

endclass
