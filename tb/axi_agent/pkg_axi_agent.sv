package pkg_axi_agent;

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import common_pkg::*;

  // include agent-related files 
  `include "sequences/udp_seq.sv"
  `include "udp_sequencer.sv"
  `include "udp_driver.sv"
  `include "udp_monitor.sv"
  
  // include agent & env files
  `include "udp_agent.sv"
  `include "udp_env.sv"

  // include test files
  `include "../tests/base_test.sv"

endpackage : pkg_axi_agent
