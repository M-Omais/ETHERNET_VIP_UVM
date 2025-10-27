class base_test extends uvm_test;
  `uvm_component_utils(base_test)
  mac_env         env;
  uvm_run_phase   run_p;


  function new(string name = "base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = mac_env::type_id::create("env", this);
  endfunction
  
  function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);

    uvm_top.print_topology();
    `uvm_info(get_type_name(), "End of elaboration phase", UVM_LOW)
    run_p = uvm_run_phase::get();
    run_p.phase_done.set_drain_time(this, 1ns);
  endfunction

endclass