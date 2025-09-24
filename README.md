# ETHERNET_VIP_UVM

UVM-based Ethernet Verification IP for simulating and verifying Ethernet protocols.  
Provides reusable, configurable testbench components to accelerate functional verification.

---

## 📂 Project Structure
```bash
project_root/
├── docs/ # Documentation
│ ├── architecture/ # Block diagrams, specifications
│ └── meeting_notes/ # Weekly sync notes
├── rtl/ # Design files (DUT)
│ └── eth_mac/ # Ethernet MAC RTL
├── tb/ # Testbench directory
│ ├── common/ # Shared components
│ │ ├── sq_item.sv # Transaction class (AGREED CONTRACT)
│ │ └── pkg_common.sv # Common parameters, types, utilities
│ ├── interfaces/ # Interface definitions
│ │ ├── xgmii_if.sv # XGMII interface with clocking blocks
│ │ └── axi_stream_if.sv # AXI Stream interface with clocking blocks
│ ├── xgmii_agent/ # PERSON A's domain
│ │ ├── pkg_xgmii_agent.sv
│ │ ├── xgmii_agent.sv
│ │ ├── xgmii_driver.sv
│ │ ├── xgmii_monitor.sv
│ │ ├── xgmii_sequencer.sv
│ │ └── sequences/ # XGMII sequences
│ │ ├── xgmii_base_seq.sv
│ │ └── xgmii_simple_seq.sv
│ ├── axi_agent/ # PERSON B's domain
│ │ ├── pkg_axi_agent.sv
│ │ ├── axi_agent.sv
│ │ ├── axi_driver.sv
│ │ ├── axi_monitor.sv
│ │ ├── axi_sequencer.sv
│ │ └── sequences/ # AXI sequences
│ │ ├── axi_base_seq.sv
│ │ └── axi_simple_seq.sv
│ ├── env/ # Integration components
│ │ ├── pkg_env.sv
│ │ ├── mac_env.sv # Main environment (owns both agents)
│ │ ├── scoreboard.sv # Cross-interface checker
│ │ ├── coverage.sv # Functional coverage
│ │ └── virtual_sequences/ # Coordinated sequences
│ │ └── mac_vseq.sv
│ ├── tests/ # Test scenarios
│ │ ├── base_test.sv
│ │ ├── test_xgmii_to_axi.sv
│ │ └── test_axi_to_xgmii.sv
│ └── tb_top.sv # Top-level testbench module
├── sim/ # Simulation directory
│ ├── scripts/ # Simulation scripts
│ │ ├── compile.tcl # Compilation script
│ │ └── run_test.tcl # Test run script
│ ├── work/ # Simulation working directory
│ └── logs/ # Simulation logs
└── verification_plan/ # Verification documentation
├── test_plan.md # Overall test plan
├── coverage_plan.md # Coverage goals
└── results/ # Verification results
```
