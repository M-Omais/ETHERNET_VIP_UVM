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
	    static bit collecting = 0;  // keep track across cycles
	    static logic [63:0] data_q[$];
	    static logic [63:0] ctrl_q[$];
		forever begin
		
		    // Capture each lane
		    for (int i = 0; i < 8; i++) begin
		        byte data_lane = vif.data[8*i +: 8];
		        bit  ctrl_lane = vif.ctrl[i];

		        if (ctrl_lane) begin
		            case (data_lane)
		                8'h07: begin
		                    `uvm_info("MONITOR_WRITE", "Received IDLE character", UVM_DEBUG);
		                end
		                8'hFB: begin
		                    `uvm_info("MONITOR_WRITE", "Received START character", UVM_HIGH);
		                    collecting = 1;
		                    data_q.delete();  // reset queues at new frame
		                    ctrl_q.delete();
		                end
		                8'hFD: begin
		                    `uvm_info("MONITOR_WRITE", "Received END character", UVM_HIGH);
		                    collecting = 0;
					        data_q.push_back(vif.data);
					        ctrl_q.push_back(vif.ctrl);
		                    // Create transaction once per frame
		                    tr = sq_item::type_id::create("tr", this);
		                    tr.data_out = new[data_q.size()];
		                    tr.ctrl_out = new[ctrl_q.size()];

		                    for (int j = 0; j < data_q.size(); j++) begin
		                        tr.data_out[j] = data_q[j];
		                        tr.ctrl_out[j] = ctrl_q[j];
		                    end

		                    // Publish transaction
		                    dut_write.write(tr);
							// tr.print_data();
		                end
		            endcase
		        end
		    end

		    // Collect payload words when active
		    if (collecting) begin
		        data_q.push_back(vif.data);
		        ctrl_q.push_back(vif.ctrl);
		        `uvm_info("MONITOR_WRITE", $sformatf("Captured tdata: %h", vif.data), UVM_HIGH);
		    end
		@(posedge vif.clk);
		end
	endtask

	
	virtual task read_cycle();
	    sq_item tr;
	    static bit collecting = 0;    // keep track of frame
	    static logic [63:0] data_q[$];
	    static logic [63:0] ctrl_q[$];

	    forever begin

	        // Check each lane
	        for (int i = 0; i < 8; i++) begin
	            byte data_lane = vif.tdata[8*i +: 8];
	            bit  ctrl_lane = vif.tctrl[i];

	            if (ctrl_lane) begin
	                case (data_lane)
	                    8'h07: begin
	                        `uvm_info("MONITOR_READ", "Received IDLE character", UVM_DEBUG);
	                    end
	                    8'hFB: begin
	                        `uvm_info("MONITOR_READ", "Received START character", UVM_HIGH);
	                        collecting = 1;
	                        data_q.delete();
	                        ctrl_q.delete();
	                    end
	                    8'hFD: begin
	                        `uvm_info("MONITOR_READ", "Received END character", UVM_HIGH);
	                        collecting = 0;

	                        // push the last word
	                        data_q.push_back(vif.tdata);
	                        ctrl_q.push_back(vif.tctrl);

	                        // Build transaction once frame ends
	                        tr = sq_item::type_id::create("tr", this);
	                        tr.data_out = new[data_q.size()];
	                        tr.ctrl_out = new[ctrl_q.size()];
	                        for (int j = 0; j < data_q.size(); j++) begin
	                            tr.data_out[j] = data_q[j];
	                            tr.ctrl_out[j] = ctrl_q[j];
	                        end

	                        dut_read.write(tr);
	                    end
	                endcase
	            end
	        end

	        // Collect payload during active frame
	        if (collecting) begin
	            data_q.push_back(vif.tdata);
	            ctrl_q.push_back(vif.tctrl);
	            `uvm_info("MONITOR_READ", $sformatf("Captured tdata: %h", vif.tdata), UVM_MEDIUM);
	        end

	        @(posedge vif.clk);
	    end
	endtask


endclass //xgmii_monitor extends uvm_monitor