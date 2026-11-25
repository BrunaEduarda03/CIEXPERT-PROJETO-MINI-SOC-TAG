// spi_write_seq.sv - escreve data no registrador addr
class spi_write_seq extends uvm_sequence #(spi_item);
  `uvm_object_utils(spi_write_seq)

  bit [5:0]  addr;
  bit [31:0] data;

  function new(string name = "spi_write_seq");
    super.new(name);
  endfunction

  task body();
    req = spi_item::type_id::create("req");
    start_item(req);
    req.op   = SPI_WRITE;
    req.addr = addr;
    req.data = data;
    finish_item(req);
  endtask
endclass
