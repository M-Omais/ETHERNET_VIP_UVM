class xgmii_monitor extends uvm_monitor;
  `uvm_component_utils(xgmii_monitor)

  uvm_analysis_port #(xgmii_seq_item) dut_write;   
  uvm_analysis_port #(xgmii_seq_item) dut_read;

  bit collecting = 0;
  logic [63:0] data_q[$];
  logic [63:0] ctrl_q[$];

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
    dut_write = new("dut_write", this);
    dut_read  = new("dut_read",  this);
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
    xgmii_seq_item tr;

    forever begin
      @(posedge vif.clk)begin
        tr = xgmii_seq_item::type_id::create("tr", this);
        tr.data_out    = new[1];
        tr.ctrl_out    = new[1]; 
        tr.data_out[0] = vif.data;
        tr.ctrl_out[0] = vif.ctrl;
        dut_write.write(tr);
      end
    end
  endtask

  
  virtual task read_cycle();
      xgmii_seq_item tr;

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
                        tr = xgmii_seq_item::type_id::create("tr", this);
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