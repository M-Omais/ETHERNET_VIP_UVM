// Driver receives the stimulus from sequence via sequencer and drives on interface signals.
class udp_driver extends uvm_driver #(udp_seq_item);

  `uvm_component_utils(udp_driver)

  virtual udp_if    vif;   // Virtual interface handle
  udp_seq_item      item;  // Current sequence item

  // Constructor
  function new(string name="udp_driver", uvm_component parent);
    super.new(name, parent);
  endfunction

  // Build phase
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual udp_if)::get(this,"","udp_vif",vif)) begin
      `uvm_fatal("NO_VIF", $sformatf("virtual interface must be set for: %s.vif", get_full_name()))
    end
  endfunction

  // Run phase → drive items
  task run_phase(uvm_phase phase);
    super.run_phase(phase);

    // Wait for reset deassertion
    wait(vif.rst);
    wait(!vif.rst);
    `uvm_info("DRIVER", "Reset deasserted, starting driver", UVM_LOW);

    // Initialize outputs safe (avoid X-propagation)
    vif.s_udp_hdr_valid          <= 0;
    vif.s_udp_ip_dscp            <= '0;
    vif.s_udp_ip_ecn             <= '0;
    vif.s_udp_ip_ttl             <= '0;
    vif.s_udp_ip_source_ip       <= '0;
    vif.s_udp_ip_dest_ip         <= '0;
    vif.s_udp_source_port        <= '0;
    vif.s_udp_dest_port          <= '0;
    vif.s_udp_length             <= '0;
    vif.s_udp_checksum           <= '0;

    vif.s_udp_payload_axis_tdata  <= '0;
    vif.s_udp_payload_axis_tvalid <= 0;
    vif.s_udp_payload_axis_tlast  <= 0;
    vif.s_udp_payload_axis_tuser  <= 0;

    forever begin
      // Block until we get a new transaction
      seq_item_port.get_next_item(item); //seq_item_port:TLM port in driver that connects to sequencer, to let driver pull transactions

      `uvm_info("DRIVER",$sformatf("Driving UDP packet: src_port=%0d dst_port=%0d len=%0d",
                   item.s_udp_source_port, item.s_udp_dest_port, item.s_udp_length),UVM_LOW)

      drive_task(item);
      // #1ns;
      seq_item_port.item_done();

      // Random idle cycles between packets (simulate realistic gaps)
      // repeat($urandom_range(0,3)) @(posedge vif.clk);
    end
  endtask

  // Drive UDP transaction onto interface
  virtual task drive_task(udp_seq_item tr); 

    // Drive header first
    @(posedge vif.clk);
    vif.s_udp_hdr_valid      <= 1;
    vif.s_udp_ip_dscp        <= tr.s_udp_ip_dscp;
    vif.s_udp_ip_ecn         <= tr.s_udp_ip_ecn;
    vif.s_udp_ip_ttl         <= tr.s_udp_ip_ttl;
    vif.s_udp_ip_source_ip   <= tr.s_udp_ip_source_ip;
    vif.s_udp_ip_dest_ip     <= tr.s_udp_ip_dest_ip;
    vif.s_udp_source_port    <= tr.s_udp_source_port;
    vif.s_udp_dest_port      <= tr.s_udp_dest_port;
    vif.s_udp_length         <= tr.s_udp_length;
    vif.s_udp_checksum       <= tr.s_udp_checksum;

    // Wait for DUT ready
    wait(vif.s_udp_hdr_ready);
    @(posedge vif.clk);
    vif.s_udp_hdr_valid <= 0;

    // Drive payload byte by byte
    foreach (tr.s_udp_payload_data[i]) begin
      @(posedge vif.clk);
      vif.s_udp_payload_axis_tdata  <= tr.s_udp_payload_data[i];
      vif.s_udp_payload_axis_tvalid <= 1;
      vif.s_udp_payload_axis_tuser  <= tr.s_udp_payload_user;
      vif.s_udp_payload_axis_tlast  <= (i == tr.s_udp_payload_data.size()-1);

      `uvm_info("DRIVER", $sformatf("Payload[%0d] = 0x%0h", i, tr.s_udp_payload_data[i]), UVM_HIGH)

      // Wait until DUT accepts (tready high)
      wait(vif.s_udp_payload_axis_tready);
    end

    // Deassert after last beat
    @(posedge vif.clk);
    vif.s_udp_payload_axis_tvalid <= 0;
    vif.s_udp_payload_axis_tlast  <= 0;
    vif.s_udp_payload_axis_tuser  <= 0;
    vif.s_udp_payload_axis_tdata  <= '0;

  endtask : drive_task

endclass : udp_driver
