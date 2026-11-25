// spi_read_seq.sv - le o registrador addr; o valor lido fica em rdata
class spi_read_seq extends uvm_sequence #(spi_item);
  `uvm_object_utils(spi_read_seq)

  bit [5:0]    addr;
  logic [31:0] rdata;

  function new(string name = "spi_read_seq");
    super.new(name);
  endfunction

  task body();
    req = spi_item::type_id::create("req");
    start_item(req);
    req.op   = SPI_READ;
    req.addr = addr;
    finish_item(req);                // quando volta, o driver ja preencheu req.rdata
    rdata = req.rdata;
  endtask
endclass
