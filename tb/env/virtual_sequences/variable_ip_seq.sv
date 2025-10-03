class variable_ip_seq extends uvm_sequence;
    `uvm_object_utils(variable_ip_seq)
    `uvm_declare_p_sequencer(virtual_sequencer)

    function new(string name="variable_ip_seq");
        super.new(name);
    endfunction

    task body();
        variable_hanshake_seq hs[$];
        variable_udp_seq      udp[$];
        variable_xgmii_seq    xgmii[$];

        // --------------------------------
        // Create 3 handshake/udp/xgmii seqs
        // --------------------------------
        for (int i = 0; i < 3; i++) begin
            hs.push_back(variable_hanshake_seq::type_id::create($sformatf("hs%0d", i+1)));
            udp.push_back(variable_udp_seq::type_id::create($sformatf("udp%0d", i+1)));
            xgmii.push_back(variable_xgmii_seq::type_id::create($sformatf("xgmii%0d", i+1)));
        end

        // --------------------------------
        // Assign unique IP/MACs
        // --------------------------------
        hs[0].custom_mac = 48'h5a5152535455;
        hs[0].custom_ip  = 32'hc0a80164;  // 192.168.1.100
        hs[1].custom_mac = 48'h6a6162636465;
        hs[1].custom_ip  = 32'hc0a80165;  // 192.168.1.101
        hs[2].custom_mac = 48'h7a7172737475;
        hs[2].custom_ip  = 32'hc0a80166;  // 192.168.1.102

        udp[0].custom_ip = 32'hc0a80164;
        udp[1].custom_ip = 32'hc0a80165;
        udp[2].custom_ip = 32'hc0a80166;

        xgmii[0].custom_mac = 48'h5a5152535455;
        xgmii[0].custom_ip  = 32'hc0a80164;
        xgmii[1].custom_mac = 48'h6a6162636465;
        xgmii[1].custom_ip  = 32'hc0a80165;
        xgmii[2].custom_mac = 48'h7a7172737475;
        xgmii[2].custom_ip  = 32'hc0a80166;

        // --------------------------------
        // Run sequences (serial or parallel)
        // --------------------------------

        // Option 1: Serial execution (your current style)
        foreach (hs[i]) begin
            hs[i].start(p_sequencer);
            #100;
        end

        foreach (udp[i]) begin
            udp[i].start(p_sequencer.udp_sequencer_inst);
            #100;
        end

        foreach (xgmii[i]) begin
            xgmii[i].start(p_sequencer.xgmii_sequencer_inst);
            #100;
        end

        // Option 2: Run them all in parallel
        // fork
        //   foreach (hs[i]) hs[i].start(p_sequencer);
        //   foreach (udp[i]) udp[i].start(p_sequencer.udp_sequencer_inst);
        //   foreach (xgmii[i]) xgmii[i].start(p_sequencer.xgmii_sequencer_inst);
        // join

    endtask
endclass
