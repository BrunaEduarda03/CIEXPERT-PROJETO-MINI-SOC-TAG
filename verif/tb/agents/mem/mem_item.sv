//-----------------------------------------------------------------------------
// mem_item.sv
// Transacao da MEMORY DATA: uma escrita ou uma leitura de uma palavra.
// Os campos tem o mesmo nome dos sinais da mem_if / portas do DUT.
// mem_o_data e preenchido pelo driver (modo ativo) ou pelo monitor; e logic
// para que X (memoria sem reset) seja visivel no scoreboard.
//-----------------------------------------------------------------------------
class mem_item extends uvm_sequence_item;

  rand bit        mem_i_wr_en;   // 1 = escrita, 0 = leitura
  rand bit [9:0]  mem_i_addr;
  rand bit [31:0] mem_i_data;    // dado escrito (so em escrita)
  logic    [31:0] mem_o_data;    // dado lido    (so em leitura)

  `uvm_object_utils_begin(mem_item)
    `uvm_field_int(mem_i_wr_en, UVM_DEFAULT)
    `uvm_field_int(mem_i_addr,  UVM_DEFAULT | UVM_HEX)
    `uvm_field_int(mem_i_data,  UVM_DEFAULT | UVM_HEX)
    `uvm_field_int(mem_o_data,  UVM_DEFAULT | UVM_HEX | UVM_NOCOMPARE)
  `uvm_object_utils_end

  function new(string name = "mem_item");
    super.new(name);
  endfunction

  function string convert2string();
    if (mem_i_wr_en)
      return $sformatf("MEM WRITE mem_i_addr=0x%03h mem_i_data=0x%08h", mem_i_addr, mem_i_data);
    else
      return $sformatf("MEM READ  mem_i_addr=0x%03h mem_o_data=0x%08h", mem_i_addr, mem_o_data);
  endfunction

endclass : mem_item
