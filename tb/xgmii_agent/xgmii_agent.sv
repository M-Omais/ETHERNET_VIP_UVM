class xgmii_agent extends uvm_agent;
  `uvm_component_utils(xgmii_agent)

  xgmii_driver              drv;
  xgmii_monitor             mon;
  xgmii_sequencer           seqr;
  
  uvm_active_passive_enum   is_active;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(uvm_active_passive_enum)::get(this, "", "is_active", is_active)) begin
      `uvm_info(get_type_name(), "No config found for is_active, using default", UVM_LOW)
    end

    if (is_active == UVM_ACTIVE) begin
      drv = xgmii_driver::type_id::create("drv", this);
      seqr = xgmii_sequencer::type_id::create("seqr", this);
    end

    mon = xgmii_monitor::type_id::create("mon", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    if (is_active == UVM_ACTIVE) begin
      drv.seq_item_port.connect(seqr.seq_item_export);
    end
  endfunction

endclass