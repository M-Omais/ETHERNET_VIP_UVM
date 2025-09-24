// Agent = container for sequencer, driver, monitor
class udp_agent extends uvm_agent;

  `uvm_component_utils(udp_agent)

  // Components inside agent
  udp_sequencer   seqr;
  udp_driver      drv;
  udp_monitor     mon;

  // Config knob: active or passive agent
  uvm_active_passive_enum is_active = UVM_ACTIVE;

  // Constructor
  function new(string name = "udp_agent", uvm_component parent);
    super.new(name, parent);
  endfunction

  // Build: create components depending on active/passive
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    mon = udp_monitor::type_id::create("mon", this);

    if (is_active == UVM_ACTIVE) begin
      seqr = udp_sequencer::type_id::create("seqr", this);
      drv  = udp_driver   ::type_id::create("drv",  this);
    end
  endfunction

  // Connect sequencer <-> driver
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    if (is_active == UVM_ACTIVE) begin
      drv.seq_item_port.connect(seqr.seq_item_export);
    end
  endfunction

endclass : udp_agent
