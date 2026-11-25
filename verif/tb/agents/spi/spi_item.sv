// spi_item.sv - uma transacao SPI: "escreva data no registrador addr" ou "leia addr"
typedef enum bit {SPI_READ, SPI_WRITE} spi_op_e;

class spi_item extends uvm_sequence_item;
  `uvm_object_utils(spi_item)

  spi_op_e     op;
  bit   [5:0]  addr;    // registrador (0x00 a 0x3F)
  bit   [31:0] data;    // WRITE: dado a escrever
  logic [31:0] rdata;   // READ: dado lido

  function new(string name = "spi_item");
    super.new(name);
  endfunction

  function string convert2string();
    return $sformatf("%s addr=0x%02h data=0x%08h", op.name(), addr, (op == SPI_WRITE) ? data : rdata);
  endfunction
endclass
