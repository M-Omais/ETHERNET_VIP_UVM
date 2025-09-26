class scoreboard extends uvm_scoreboard;
	`uvm_component_utils(scoreboard)

	// Analysis import declarations
	`uvm_analysis_imp_decl(_expected)
	`uvm_analysis_imp_decl(_actual)

	// Analysis implementation ports
	uvm_analysis_imp_expected#(sq_item, scoreboard) in_port;
	uvm_analysis_imp_actual#(sq_item, scoreboard)   out_port;
	int match, mis_match;

	// Constructor: create imp ports and initialize stats
	function new(string name, uvm_component parent);
		super.new(name, parent);
		match = 0;
		mis_match = 0;
	endfunction

	// Build phase: nothing additional needed
	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		in_port  = new("in_port", this);
		out_port = new("out_port", this);
		match = 0;
		mis_match = 0;
	endfunction
	virtual function void write_expected(sq_item tr);
		`uvm_info("SCOREBOARD_EXPECTED", tr.print_data(), UVM_LOW)
				
	endfunction

	// Collect and compare actual transactions
	virtual function void write_actual(sq_item tr);
			`uvm_info("SCOREBOARD_ACTUAL",tr.print_data(), UVM_LOW)
		// tr.print_data();
		// `uvm_info("SCOREBOARD_ACTUAL", 
		//   $sformatf({
		//     "\n----------------------------------------\n",
		//     "   ACTUAL seq_item\n",
		//     "----------------------------------------\n",
		//     "  src_addr : %h\n",
		//     "  dst_addr : %h\n",
		//     "  eth_type : %h\n",
		//     "  src_ip   : %h\n",
		//     "  dst_ip   : %h\n",
		//     "  src_port : %0d\n",
		//     "  dst_port : %0d\n",
		//     "----------------------------------------"
		//   },
		//   tr.src_addr, tr.dst_addr, tr.eth_type,
		//   tr.src_ip, tr.dst_ip, tr.src_port, tr.dst_port),
		//   UVM_LOW
		// );
	endfunction
		
	


	// Report final statistics
	virtual function void report_phase(uvm_phase phase);
		real error_pct = (match + mis_match) ? (100.0 * mis_match / (match + mis_match)) : 0.0;
		`uvm_info("scoreboard_REPORT", $sformatf("Total Matches: %0d, Total Mismatches: %0d, Error Percentage: %.2f%%", match, mis_match, error_pct), UVM_LOW)
	endfunction

endclass : scoreboard