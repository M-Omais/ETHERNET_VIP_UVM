// Sequencer connects sequence (udp_seq) and driver (axis_driver)
class axis_sequencer extends uvm_sequencer #(udp_seq_item);
  `uvm_component_utils(axis_sequencer)

//Constructor
  function new(string name="axis_sequencer", uvm_component parent);
    super.new(name, parent);
  endfunction : new

endclass : axis_sequencer
