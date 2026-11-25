//-----------------------------------------------------------------------------
// spi_base_seq.sv
// Base das sequences SPI: tarefas do_write()/do_read() no nivel de registrador.
// Na leitura o dado volta por get_response() (o spi_driver faz put_response).
//-----------------------------------------------------------------------------
class spi_base_seq extends uvm_sequence #(spi_item);
  `uvm_object_utils(spi_base_seq)

  function new(string name = "spi_base_seq");
    super.new(name);
  endfunction

  task do_write(bit [5:0] addr, bit [31:0] data);
    spi_item t = spi_item::type_id::create("t");
    start_item(t);
    t.rwb  = 1'b0;
    t.addr = addr;
    t.data = data;
    finish_item(t);
  endtask

  task do_read(bit [5:0] addr, output logic [31:0] data);
    spi_item t = spi_item::type_id::create("t");
    spi_item rsp;
    start_item(t);
    t.rwb  = 1'b1;
    t.addr = addr;
    t.data = '0;
    finish_item(t);
    get_response(rsp);
    data = rsp.rdata;
  endtask

endclass : spi_base_seq
