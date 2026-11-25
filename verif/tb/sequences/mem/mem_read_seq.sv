//-----------------------------------------------------------------------------
// mem_read_seq.sv
// Leitura unitaria: mem_read_seq(addr) -> rdata.
//-----------------------------------------------------------------------------
class mem_read_seq extends mem_base_seq;
  `uvm_object_utils(mem_read_seq)

  rand bit [9:0]  addr;
  logic    [31:0] rdata;

  function new(string name = "mem_read_seq");
    super.new(name);
  endfunction

  task body();
    do_read(addr, rdata);
  endtask

endclass : mem_read_seq
