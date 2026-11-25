//-----------------------------------------------------------------------------
// mem_write_seq.sv
// Escrita unitaria: mem_write_seq(addr, data).
//-----------------------------------------------------------------------------
class mem_write_seq extends mem_base_seq;
  `uvm_object_utils(mem_write_seq)

  rand bit [9:0]  addr;
  rand bit [31:0] data;

  function new(string name = "mem_write_seq");
    super.new(name);
  endfunction

  task body();
    do_write(addr, data);
  endtask

endclass : mem_write_seq
