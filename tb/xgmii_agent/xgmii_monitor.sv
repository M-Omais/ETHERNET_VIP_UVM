class xgmii_monitor extends uvm_monitor;
    `uvm_component_utils(xgmii_monitor)
	uvm_analysis_port #(sq_item) dut_write;   
    uvm_analysis_port #(sq_item) dut_read;
    function new(string name , uvm_component parent);
        super.new(name,parent);
    endfunction //new()
	bit start = 0;
	bit tstart = 0;
    virtual xgmii_if vif;
	logic[63:0] data[$];
	logic[63:0] tdata[$];

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        dut_write = new("dut_write",this);
        dut_read = new("dut_read",this);
		if (!uvm_config_db #(virtual xgmii_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal(get_type_name(),"UNABLE TO GET VIRTUAL INTERFACE")
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
		fork
			write_cycle();
			read_cycle();
		join
    endtask // run_phase
	virtual task write_cycle();
		sq_item tr;
		int length;
		tr = sq_item::type_id::create("tr", this);
		forever begin
			@(posedge vif.clk);
			for (int i = 0; i<8;i++ ) begin
				byte data_lane = vif.data[8*i +: 8];  // Extract 8 bits (one byte)
				bit  ctrl_lane = vif.ctrl[i];         // Extract control bit for that lane
				if(ctrl_lane == 1'b1) begin
					// `uvm_info(get_type_name(), $sformatf("Received control character on lane %0d: %h", i, data_lane), UVM_LOW);
					case (data_lane)
						8'h07: begin
						`uvm_info("MONITOR_WRITE", "Received IDLE character", UVM_DEBUG);
						end
						8'hFB: begin
						`uvm_info("MONITOR_WRITE", "Received START character", UVM_LOW);	
						start = 1;
						end
						8'hFD: begin
							`uvm_info("MONITOR_WRITE", "Received END character", UVM_LOW);
							start = 0;
							data.push_back(vif.data);
							
							tr.dst_addr = {data[1][7:0], data[1][15:8], data[1][23:16], data[1][31:24], data[1][39:32], data[1][47:40]};
							tr.src_addr = {data[1][55:48], data[1][63:56], data[2][7:0], data[2][15:8], data[2][23:16], data[2][31:24]};
							tr.eth_type = {data[2][39:32], data[2][47:40]};
							 length = {data[3][7:0], data[3][15:8]} - 28; //IP (20) and UDP (8) header lengths
							$display("Packet Length: %0d bytes", length);
							if(tr.eth_type == 16'h0800) begin
								tr.src_ip = {data[4][23:16], data[4][31:24], data[4][39:32], data[4][47:40]};
								tr.dst_ip = {data[4][55:48], data[4][63:56], data[5][7:0], data[5][15:8]};
								tr.src_port = {data[5][23:16], data[5][31:24]};
								tr.dst_port = {data[5][39:32], data[5][47:40]};
								tr.payload = new[length];
								for (int j = 0; j < length; j++) begin
									tr.payload[j] = data[6 + ((j+2)*8)/64][((j+2)*8)%64 +: 8];
								end
								for (int j = 0; j < tr.payload.size(); j++) begin
									`uvm_info("MONITOR_WRITE", $sformatf("Payload[%0d]: %0h", j, tr.payload[j]), UVM_HIGH);
								end
							end
							if(tr.eth_type == 16'h0806)begin
								`uvm_info("MONITOR_READ", "ARP Packet Detected", UVM_LOW);
								tr.src_ip = {data[4][39:32], data[4][47:40], data[4][55:48], data[4][63:56]};
								tr.dst_ip =  {data[5][55:48],data[5][63:56],data[6][7:0], data[6][15:8]};
							end
							// tr.dst_addr = 48'h020000000000;
							`uvm_info("MONITOR_WRITE", $sformatf(
								"tr.src_addr: %h, tr.dst_addr: %h, tr.eth_type: %h, tr.src_ip: %h, tr.dst_ip: %h, tr.src_port: %d, tr.dst_port: %d", tr.src_addr, tr.dst_addr, tr.eth_type, tr.src_ip, tr.dst_ip, tr.src_port, tr.dst_port), UVM_LOW);
							for (int j = 0; j < data.size(); j++) begin
								`uvm_info("MONITOR_WRITE", $sformatf("Data[%0d]: %h", j, data[j]), UVM_HIGH);
							end
							data.delete();
							dut_write.write(tr);
						// $finish();
						end
						default: `uvm_info("MONITOR_WRITE", $sformatf("Received unknown control character: %h", data_lane), UVM_LOW)
					endcase
				end 
			end
			if (start) begin
				
				data.push_back(vif.data);
				`uvm_info("MONITOR_WRITE", $sformatf("Captured data: %h", vif.data), UVM_HIGH);
			end
			end
	endtask // write_cycle
	
	virtual task read_cycle();
		sq_item tr;
		int length;
		tr = sq_item::type_id::create("tr", this);
		forever begin
			@(posedge vif.clk);
			for (int i = 0; i<8;i++ ) begin
				byte data_lane = vif.tdata[8*i +: 8];  // Extract 8 bits (one byte)
				bit  ctrl_lane = vif.tctrl[i];         // Extract control bit for that lane
				if(ctrl_lane == 1'b1) begin
					// `uvm_info("MONITOR_READ", $sformatf("Received control character on lane %0d: %h", i, data_lane), UVM_LOW);
					case (data_lane)
						8'h07: begin
						`uvm_info("MONITOR_READ", "Received IDLE character", UVM_DEBUG);
						end
						8'hFB: begin
						`uvm_info("MONITOR_READ", "Received START character", UVM_LOW);	
						tstart = 1;
						end
						8'hFD: begin
							`uvm_info("MONITOR_READ", "Received END character", UVM_LOW);
							tstart = 0;
							tdata.push_back(vif.tdata);
							
							tr.dst_addr = {tdata[1][7:0], tdata[1][15:8], tdata[1][23:16], tdata[1][31:24], tdata[1][39:32], tdata[1][47:40]};
							tr.src_addr = {tdata[1][55:48], tdata[1][63:56], tdata[2][7:0], tdata[2][15:8], tdata[2][23:16], tdata[2][31:24]};
							tr.eth_type = {tdata[2][39:32], tdata[2][47:40]};
							if(tr.eth_type == 16'h0800) begin
								length = {tdata[3][7:0], tdata[3][15:8]} - 28; //IP (20) and UDP (8) header lengths
								$display("Packet Length: %0d bytes", length);
								tr.src_ip = {tdata[4][23:16], tdata[4][31:24], tdata[4][39:32], tdata[4][47:40]};
								tr.dst_ip = {tdata[4][55:48], tdata[4][63:56], tdata[5][7:0], tdata[5][15:8]};
								tr.src_port = {tdata[5][23:16], tdata[5][31:24]};
								tr.dst_port = {tdata[5][39:32], tdata[5][47:40]};
								tr.payload = new[length];
								for (int j = 0; j < length; j++) begin
									tr.payload[j] = tdata[6 + ((j+2)*8)/64][((j+2)*8)%64 +: 8];
								end
								// for (int j = 0; j < tr.payload.size(); j++) begin
								// 	`uvm_info("MONITOR_READ", $sformatf("Payload[%0d]: %0h", j, tr.payload[j]), UVM_LOW);
								// end
								`uvm_info("MONITOR_READ", $sformatf("Complete seq_item: src_addr=%h, dst_addr=%h, eth_type=%h, src_ip=%h, dst_ip=%h",
									tr.src_addr, tr.dst_addr, tr.eth_type, tr.src_ip, tr.dst_ip), UVM_LOW);
							end
							if(tr.eth_type == 16'h0806)begin
								`uvm_info("MONITOR_READ", "ARP Packet Detected", UVM_LOW);
								tr.src_ip = {tdata[4][39:32], tdata[4][47:40], tdata[4][55:48], tdata[4][63:56]};
								tr.dst_ip =  {tdata[5][55:48],tdata[5][63:56],tdata[6][7:0], tdata[6][15:8]};
								// printing entire seq_item
								`uvm_info("MONITOR_READ", $sformatf("Complete seq_item: src_addr=%h, dst_addr=%h, eth_type=%h, src_ip=%h, dst_ip=%h sport=%0d, dport=%0d",
									tr.src_addr, tr.dst_addr, tr.eth_type, tr.src_ip, tr.dst_ip, tr.src_port, tr.dst_port), UVM_LOW);
							end
							// tr.dst_addr = 48'h020000000000;
							`uvm_info("MONITOR_READ", $sformatf(
								"tr.src_addr: %h, tr.dst_addr: %h, tr.eth_type: %h, tr.src_ip: %h, tr.dst_ip: %h", tr.src_addr, tr.dst_addr, tr.eth_type, tr.src_ip, tr.dst_ip), UVM_LOW);
							for (int j = 0; j < tdata.size(); j++) begin
								`uvm_info("MONITOR_READ", $sformatf("Data[%0d]: %h", j, tdata[j]), UVM_HIGH);
							end
							tdata.delete();
							dut_read.write(tr);
							// $finish();
						end
						default: `uvm_info("MONITOR_READ", $sformatf("Received unknown control character: %h", data_lane), UVM_LOW)
					endcase
				end 
			end
			if (tstart) begin
				
				tdata.push_back(vif.tdata);
				`uvm_info("MONITOR_READ", $sformatf("Captured tdata: %h", vif.tdata), UVM_HIGH);
			end
		end
	endtask // read_cycle

endclass //xgmii_monitor extends uvm_monitor