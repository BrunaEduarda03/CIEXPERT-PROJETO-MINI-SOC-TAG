//-----------------------------------------------------------------------------
// spi_write_seq.sv
// Escrita de registrador: spi_write_seq(addr, data).
//-----------------------------------------------------------------------------
class spi_write_seq extends spi_base_seq;
  `uvm_object_utils(spi_write_seq)

  rand bit [5:0]  addr;
  rand bit [31:0] data;

  function new(string name = "spi_write_seq");
    super.new(name);
  endfunction

  task body();
    do_write(addr, data);
  endtask

endclass : spi_write_seq
