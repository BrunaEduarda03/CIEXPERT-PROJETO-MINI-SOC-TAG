//-----------------------------------------------------------------------------
// mem_item.sv
// Transacao da interface MEMORY DATA: "escreva data em addr" ou "leia addr".
// Em uma leitura, rdata e preenchido pelo driver (resposta para a sequence)
// e pelo monitor (valor visto no fio, usado pelo scoreboard).
//-----------------------------------------------------------------------------
typedef enum bit {MEM_READ = 1'b0, MEM_WRITE = 1'b1} mem_op_e;

class mem_item extends uvm_sequence_item;

  rand mem_op_e     op;
  rand bit [9:0]    addr;
  rand bit [31:0]   data;    // dado escrito (WRITE)
  logic    [31:0]   rdata;   // dado lido (READ); logic para preservar X

  `uvm_object_utils_begin(mem_item)
    `uvm_field_enum(mem_op_e, op, UVM_DEFAULT)
    `uvm_field_int(addr,  UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(data,  UVM_DEFAULT)
    `uvm_field_int(rdata, UVM_DEFAULT | UVM_NOCOMPARE)
  `uvm_object_utils_end

  function new(string name = "mem_item");
    super.new(name);
  endfunction

  function string convert2string();
    if (op == MEM_WRITE)
      return $sformatf("WRITE addr=%4d data=0x%08h", addr, data);
    else
      return $sformatf("READ  addr=%4d data=0x%08h", addr, rdata);
  endfunction

endclass : mem_item
