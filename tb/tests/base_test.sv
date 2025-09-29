class base_test extends uvm_test;
	`uvm_component_utils(base_test)
	mac_env env;

	function new(string name = "base_test", uvm_component parent = null);
		super.new(name, parent);
	endfunction

	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		env = mac_env::type_id::create("env", this);
	endfunction

	virtual task run_phase(uvm_phase phase);
		phase.raise_objection(this, "Running base_test");
		phase.drop_objection(this, "Finished base_test");
		
	endtask
	function void end_of_elaboration_phase(uvm_phase phase);
		super.end_of_elaboration_phase(phase);
		// uvm_top.print_topology();
		`uvm_info(get_type_name(), "End of elaboration phase", UVM_LOW)
	endfunction
endclass