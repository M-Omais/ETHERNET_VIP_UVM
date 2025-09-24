typedef enum { READ, WRITE } transfer_type;
class sq_item extends uvm_sequence_item;

	`uvm_object_utils(sq_item)
	//Eth header fields
	rand bit [47:0] dst_addr;
	rand bit [47:0] src_addr;
	rand bit [15:0] eth_type;
	//IP header fields
	rand bit [31:0] src_ip;
	rand bit [31:0] dst_ip;
	// UDP header fields
	rand bit [15:0] src_port;
	rand bit [15:0] dst_port;
	// Payload
	rand logic [7:0] payload[$];
	rand transfer_type transfer;
endclass