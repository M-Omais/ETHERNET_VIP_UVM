# vlib work
# vlog -sv +acc -lint package.sv +define+UVM_REPORT_DISABLE_FILE_LINE 
# vlog -sv +acc -lint ../../rtl/*.v ../interfaces/*.sv ../top.sv +define+UVM_REPORT_DISABLE_FILE_LINE 
vlog -sv "+acc" -lint "+define+UVM_REPORT_DISABLE_FILE_LINE" ../../rtl/*.v ../interfaces/*.sv ./package.sv ../top.sv
vsim -sv_lib frame -classdebug -uvmcontrol=all -voptargs=+acc +UVM_NO_RELNOTES +UVM_NO_MSG=PHASESEQ +UVM_NO_MSG=PH_READY_TO_END  +UVM_TESTNAME=handshake_test work.top -do "run 0"
# 	+UVM_NO_RELNOTES  +UVM_NO_MSG=PHASESEQ +UVM_NO_MSG=PH_READY_TO_END 
add wave -position insertpoint sim:/top/dut/*
add wave -position insertpoint sim:/top/dut/udp_complete_inst/ip_complete_64_inst/arp_inst/*
add wave -position insertpoint sim:/top/dut/udp_complete_inst/ip_complete_64_inst/arp_inst/arp_cache_inst/*

# add wave -position insertpoint sim:/top/dut/udp_complete_inst/s_udp_payload_axis_tdata
# add wave -position insertpoint sim:/top/dut/udp_complete_inst/m_udp_payload_axis_tdata
# add wave -position insertpoint sim:/top/dut/udp_complete_inst/m_udp_payload_axis_tdata
# add wave -position insertpoint sim:/top/dut/*tdata
# add wave -position insertpoint sim:/top/udp_vif/*
# add wave -position insertpoint sim:/top/dut/s_eth*
# add wave -position insertpoint sim:/top/dut/m_eth*
run -all