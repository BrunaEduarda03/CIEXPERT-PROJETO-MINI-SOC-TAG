// mem_read_seq.sv - uma leitura de addr; o valor lido fica em rdata
class mem_read_seq extends uvm_sequence #(mem_item);
  `uvm_object_utils(mem_read_seq)

  bit [9:0]    addr;
  logic [31:0] rdata;

  function new(string name = "mem_read_seq");
    super.new(name);
  endfunction

  task body();
    req = mem_item::type_id::create("req");
    start_item(req);
    req.op   = MEM_READ;
    req.addr = addr;
    finish_item(req);                // quando volta, o driver ja preencheu req.rdata
    rdata = req.rdata;
  endtask
endclass
