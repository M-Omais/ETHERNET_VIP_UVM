// Sequencer connects sequence (udp_seq) and driver (udp_driver)
class udp_sequencer extends uvm_sequencer #(udp_seq_item);
  `uvm_component_utils(udp_sequencer)

//Constructor
  function new(string name="udp_sequencer", uvm_component parent);
    super.new(name, parent);
  endfunction : new

endclass : udp_sequencer
