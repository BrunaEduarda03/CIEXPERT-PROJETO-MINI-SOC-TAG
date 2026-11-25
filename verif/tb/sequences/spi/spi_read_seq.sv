//-----------------------------------------------------------------------------
// spi_read_seq.sv
// Leitura de registrador: spi_read_seq(addr) -> rdata.
//-----------------------------------------------------------------------------
class spi_read_seq extends spi_base_seq;
  `uvm_object_utils(spi_read_seq)

  rand bit [5:0]  addr;
  logic    [31:0] rdata;

  function new(string name = "spi_read_seq");
    super.new(name);
  endfunction

  task body();
    do_read(addr, rdata);
  endtask

endclass : spi_read_seq
