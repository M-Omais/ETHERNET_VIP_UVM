class xgmii_driver extends uvm_driver#(xgmii_seq_item);
  `uvm_component_utils(xgmii_driver)

  int                   i;
  int                   ret;
  virtual xgmii_if      vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    if (!uvm_config_db#(virtual xgmii_if)::get(this, "", "vif", vif)) begin
      string comp_path = this.get_full_name();         // UVM hierarchy e.g. uvm_test_top.env.agent.driver
      `uvm_fatal(get_type_name(),
        $sformatf("UNABLE TO GET VIRTUAL INTERFACE 'vif' — component: %s", comp_path)
      )
    end
  endfunction

  virtual task run_phase(uvm_phase phase);
    xgmii_seq_item tr;
      wait(vif.rst_n);
      wait(!vif.rst_n);
    forever begin
      // IDOL CASE TRANSMISSION
      vif.data <= 64'h0707070707070707; 
      vif.ctrl <= 64'hFFFFFFFFFFFFFFFF; 

      //Starting Transmission
      tr = xgmii_seq_item::type_id::create("tr", this);
      seq_item_port.get_next_item(tr);
      `uvm_info("XGMII_DRIVER", $sformatf("Received transaction:\n%s", tr.convert2string()), UVM_HIGH)
      // Prepare parameters for DPI call
      ret = tr.data_create();
      `uvm_info(get_type_name(), $sformatf("DPI function returned %0d bytes", ret), UVM_MEDIUM);
      for (int i  = 0; i < ret; i++) begin
        @(posedge vif.clk)begin
          vif.data <= tr.data_out[i]; 
          vif.ctrl <= tr.ctrl_out[i]; 
        end
      end

      vif.data <= 64'h0707070707070707; 
      vif.ctrl <= 64'hFFFFFFFFFFFFFFFF; 
      // #1ns
      seq_item_port.item_done();
    end
  endtask

endclass