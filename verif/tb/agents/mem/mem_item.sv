// mem_item.sv - uma transacao: "escreva data em addr" ou "leia addr"
typedef enum bit {MEM_READ, MEM_WRITE} mem_op_e;

class mem_item extends uvm_sequence_item;
  `uvm_object_utils(mem_item)

  mem_op_e     op;
  bit   [9:0]  addr;
  bit   [31:0] data;    // WRITE: dado a escrever
  logic [31:0] rdata;   // READ: dado lido

  function new(string name = "mem_item");
    super.new(name);
  endfunction

  function string convert2string();
    return $sformatf("%s addr=%0d data=0x%08h", op.name(), addr, (op == MEM_WRITE) ? data : rdata);
  endfunction
endclass
