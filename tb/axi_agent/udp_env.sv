// Env = container for agent(s), scoreboard, coverage
class udp_env extends uvm_env;

  `uvm_component_utils(udp_env)

  udp_agent agt; // one agent for now

  function new(string name = "udp_env", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agt = udp_agent::type_id::create("agt", this);
  endfunction

endclass : udp_env
