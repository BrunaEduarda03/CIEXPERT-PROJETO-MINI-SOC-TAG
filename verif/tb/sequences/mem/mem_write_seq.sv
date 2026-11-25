//-----------------------------------------------------------------------------
// mem_write_seq.sv - uma escrita: memory[addr] = data
//-----------------------------------------------------------------------------
class mem_write_seq extends uvm_sequence #(mem_item);
  `uvm_object_utils(mem_write_seq)

  bit [9:0]  addr;
  bit [31:0] data;

  function new(string name = "mem_write_seq");
    super.new(name);
  endfunction

  task body();
    req = mem_item::type_id::create("req");
    start_item(req);
    req.op   = MEM_WRITE;
    req.addr = addr;
    req.data = data;
    finish_item(req);
  endtask

endclass : mem_write_seq
