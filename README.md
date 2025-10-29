# ETHERNET_VIP_UVM

UVM-based Ethernet Verification IP for simulating and verifying Ethernet protocols.  
Provides reusable, configurable testbench components to accelerate functional verification.

---

## 📂 Project Structure

```bash
.
├── docs/
├── README.md
├── rtl/
│   ├── arbiter.v
│   ├── arp.v
│   ├── arp_cache.v
│   ├── arp_eth_rx.v
│   ├── arp_eth_tx.v
│   ├── axis_async_fifo.v
│   ├── axis_async_fifo_adapter.v
│   ├── axis_fifo.v
│   ├── axis_xgmii_rx_64.v
│   ├── axis_xgmii_tx_64.v
│   ├── eth_arb_mux.v
│   ├── eth_axis_rx.v
│   ├── eth_axis_tx.v
│   ├── eth_mac_10g.v
│   ├── eth_mac_10g_fifo.v
│   ├── fpga_core.v
│   ├── ip_64.v
│   ├── ip_arb_mux.v
│   ├── ip_complete_64.v
│   ├── ip_eth_rx_64.v
│   ├── ip_eth_tx_64.v
│   ├── lfsr.v
│   ├── priority_encoder.v
│   ├── udp_64.v
│   ├── udp_checksum_gen_64.v
│   ├── udp_complete_64.v
│   ├── udp_ip_rx_64.v
│   └── udp_ip_tx_64.v
├── tb/
│   ├── top.sv
│   ├── common/
│   │   ├── sq_item.sv
│   │   └── udp_seq_item.sv
│   ├── interfaces/
│   │   ├── axi_stream_if.sv
│   │   ├── udp_if.sv
│   │   └── xgmii_if.sv
│   ├── axis_agent/
│   │   ├── axis_agent.sv
│   │   ├── axis_driver.sv
│   │   ├── axis_monitor.sv
│   │   ├── axis_sequencer.sv
│   │   ├── sequences/
│   │   │   ├── back_to_back_seq.sv
│   │   │   ├── no_payload_seq.sv
│   │   │   ├── udp_seq.sv
│   │   │   └── variable_udp_seq.sv
│   ├── env/
│   │   ├── mac_env.sv
│   │   ├── scoreboard.sv
│   │   ├── virtual_sequencer.sv
│   │   └── virtual_sequences/
│   │       ├── arp_handshake_seq.sv
│   │       ├── variable_arp_seq.sv
│   │       └── variable_ip_seq.sv
│   ├── tests/
│   │   ├── base_test.sv
│   │   ├── handshake_test.sv
│   │   ├── udp_back_to_back_test.sv
│   │   ├── udp_test.sv
│   │   ├── udp_xgmii_parallel_test.sv
│   │   ├── variable_ip_test.sv
│   │   ├── xgmii_back_to_back_test.sv
│   │   └── xgmii_test.sv
│   ├── xgmii_agent/
│   │   ├── xgmii_agent.sv
│   │   ├── xgmii_driver.sv
│   │   ├── xgmii_monitor.sv
│   │   ├── xgmii_sequencer.sv
│   │   ├── sequences/
│   │   │   ├── arp_seq.sv
│   │   │   ├── variable_xgmii_seq.sv
│   │   │   ├── xgmii_back_to_back_seq.sv
│   │   │   └── xgmii_seq.sv
│   └── sim/
│       ├── certe_dump.xml
│       ├── frame.cpp
│       ├── Makefile
│       ├── package.sv
│       ├── requirements.txt
│       ├── run.do
│       ├── xgmii_frame.py
│       └── work/ (gitignored)
├── .gitignore
```
