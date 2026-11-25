//-----------------------------------------------------------------------------
// mem_read_seq.sv - uma leitura de addr; o valor lido fica em rdata.
// finish_item() so retorna depois do item_done() do driver, que ja preencheu
// req.rdata. Por isso nao e preciso get_response() (e a fila de respostas do
// sequencer nao enche quando so ha escritas).
//-----------------------------------------------------------------------------
class mem_read_seq extends uvm_sequence #(mem_item);
  `uvm_object_utils(mem_read_seq)

  bit [9:0]    addr;
  logic [31:0] rdata;   // saida

  function new(string name = "mem_read_seq");
    super.new(name);
  endfunction

  task body();
    req = mem_item::type_id::create("req");
    start_item(req);
    req.op   = MEM_READ;
    req.addr = addr;
    req.data = '0;
    finish_item(req);
    rdata = req.rdata;
  endtask

endclass : mem_read_seq
