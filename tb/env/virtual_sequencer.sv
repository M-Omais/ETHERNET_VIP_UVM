class virtual_sequencer extends uvm_sequencer;
  `uvm_component_utils(virtual_sequencer)

  // Handles to lower-level sequencers
  xgmii_sequencer xgmii_sequencer_inst;
  udp_sequencer   udp_sequencer_inst;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
endclass

