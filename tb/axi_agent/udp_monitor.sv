// Monitor is a passive component that observes DUT signals via virtual interface (vif)
// and converts them into transactions, which are sent out via analysis port to scoreboard, coverage,

class udp_monitor extends uvm_monitor;

  `uvm_component_utils(udp_monitor)  // Factory registration

  virtual udp_if vif;   // Virtual interface to DUT signals

  // Analysis port (sends observed transactions to subscribers: scoreboard, coverage, etc.)
  uvm_analysis_port #(udp_seq_item) ap_s_udp;
  uvm_analysis_port #(udp_seq_item) ap_m_udp;

  // Constructor
  function new(string name = "udp_monitor", uvm_component parent);
    super.new(name, parent);
    ap_s_udp = new("ap_s_udp", this);
    ap_m_udp = new("ap_m_udp", this);
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
    fork
      monitor_s_udp();
      monitor_m_udp();
    join
  endtask

  virtual task monitor_s_udp();
    udp_seq_item tr;
    forever begin
       // DUT Input observation (s_udp_*)
       tr = udp_seq_item::type_id::create("tr");

      // Wait for header valid & ready handshake
      @(posedge vif.clk iff (vif.s_udp_hdr_valid && vif.s_udp_hdr_ready));

      // Capture header fields
      tr.s_udp_ip_dscp      = vif.s_udp_ip_dscp;
      tr.s_udp_ip_ecn       = vif.s_udp_ip_ecn;
      tr.s_udp_ip_ttl       = vif.s_udp_ip_ttl;
      tr.s_udp_ip_source_ip = vif.s_udp_ip_source_ip;
      tr.s_udp_ip_dest_ip   = vif.s_udp_ip_dest_ip;
      tr.s_udp_source_port  = vif.s_udp_source_port;
      tr.s_udp_dest_port    = vif.s_udp_dest_port;
      tr.s_udp_length       = vif.s_udp_length;
      tr.s_udp_checksum     = vif.s_udp_checksum;

      // Capture payload byte by byte
      tr.s_udp_payload_data.delete();
      do begin
        @(posedge vif.clk iff (vif.s_udp_payload_axis_tvalid && vif.s_udp_payload_axis_tready));
        tr.s_udp_payload_data.push_back(vif.s_udp_payload_axis_tdata);
        tr.s_udp_payload_last = vif.s_udp_payload_axis_tlast;
        tr.s_udp_payload_user = vif.s_udp_payload_axis_tuser;
        tr.s_udp_payload_keep.push_back(vif.s_udp_payload_axis_tkeep);
      end while (!vif.s_udp_payload_axis_tlast);

      

      // Send transaction to analysis port
      ap_s_udp.write(tr);
      // UDP input monitor
      `uvm_info("MONITOR-S-UDP", $sformatf("UDP Input captured: %s", tr.convert2string_s_udp()), UVM_LOW);    
    end
  endtask: monitor_s_udp
  

  
  virtual task monitor_m_udp();
      udp_seq_item tr;
      forever begin

        // DUT Output observation (m_udp_*)
        // Wait for header valid & ready handshake
        tr = udp_seq_item::type_id::create("tr");
        // `uvm_info("MONITOR-ETH", $sformatf("ETH Output not captured: %s", tr.convert2string_eth()), UVM_LOW)
        while (!vif.m_udp_hdr_valid ) begin
          @(negedge vif.clk);
          `uvm_info("MONITOR-M-UDP", "WAITING", UVM_DEBUG)
        end


        // Capture Output fields
        tr.m_udp_hdr_valid          = vif.m_udp_hdr_valid;
        tr.m_udp_hdr_ready          = vif.m_udp_hdr_ready;
        tr.m_udp_eth_dest_mac       = vif.m_udp_eth_dest_mac;
        tr.m_udp_eth_src_mac        = vif.m_udp_eth_src_mac;
        tr.m_udp_eth_type           = vif.m_udp_eth_type;

        tr.m_udp_ip_version         = vif.m_udp_ip_version;
        tr.m_udp_ip_ihl             = vif.m_udp_ip_ihl;
        tr.m_udp_ip_dscp            = vif.m_udp_ip_dscp;
        tr.m_udp_ip_ecn             = vif.m_udp_ip_ecn;
        tr.m_udp_ip_length          = vif.m_udp_ip_length;
        tr.m_udp_ip_identification  = vif.m_udp_ip_identification;
        tr.m_udp_ip_flags           = vif.m_udp_ip_flags;
        tr.m_udp_ip_fragment_offset = vif.m_udp_ip_fragment_offset;
        tr.m_udp_ip_ttl             = vif.m_udp_ip_ttl;
        tr.m_udp_ip_protocol        = vif.m_udp_ip_protocol;
        tr.m_udp_ip_header_checksum = vif.m_udp_ip_header_checksum;
        tr.m_udp_ip_source_ip       = vif.m_udp_ip_source_ip;
        tr.m_udp_ip_dest_ip         = vif.m_udp_ip_dest_ip;

        tr.m_udp_source_port        = vif.m_udp_source_port;
        tr.m_udp_dest_port          = vif.m_udp_dest_port;
        tr.m_udp_length             = vif.m_udp_length;
        tr.m_udp_checksum           = vif.m_udp_checksum;

        // Capture payload stream
        tr.m_udp_payload_data.delete();

        do begin
          // Wait until payload valid is seen
          while (!vif.m_udp_payload_axis_tvalid) begin
            @(posedge vif.clk);
            `uvm_info("MONITOR-M-UDP", "Waiting for UDP payload valid...", UVM_DEBUG)
          end

          // Sample payload data when valid & ready
          if (vif.m_udp_payload_axis_tvalid) begin
            tr.m_udp_payload_data.push_back(vif.m_udp_payload_axis_tdata);
          end
          //`uvm_info("MONITOR-M-UDP", $sformatf("PAYLOAD CAPTURE: valid=%0b ready=%0b last=%0b data=%h",vif.m_udp_payload_axis_tvalid, vif.m_udp_payload_axis_tready,vif.m_udp_payload_axis_tlast, vif.m_udp_payload_axis_tdata), UVM_MEDIUM)
          //updated
          @(posedge vif.clk);
        end while (!vif.m_udp_payload_axis_tlast);


        tr.m_udp_payload_last = vif.m_udp_payload_axis_tlast;
        tr.m_udp_payload_user = vif.m_udp_payload_axis_tuser;

        // Send transaction to analysis port
        ap_s_udp.write(tr);
        // Ethernet output monitor
        `uvm_info("MONITOR-M-UDP", $sformatf("ETH Output captured: %s", tr.convert2string_m_udp()), UVM_LOW)
      end
      endtask

endclass
