class xgmii_sequencer extends uvm_sequencer#(sq_item);
	`uvm_component_utils(xgmii_sequencer)
	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction
endclass