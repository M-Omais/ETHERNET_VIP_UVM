class xgmii_seq extends uvm_sequence#(sq_item);
	`uvm_object_utils(xgmii_seq)
	function new(string name = "xgmii_seq");
		super.new(name);
	endfunction

	virtual task body();
		sq_item tr;
		`uvm_do(tr);

	endtask
endclass