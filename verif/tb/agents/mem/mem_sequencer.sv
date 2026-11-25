//-----------------------------------------------------------------------------
// mem_sequencer.sv
// Sequencer do VIP MEMORY DATA. Classe (e nao typedef) para poder ser
// estendida depois (ex.: referencia ao cfg para sequences).
//-----------------------------------------------------------------------------
class mem_sequencer extends uvm_sequencer #(mem_item);
  `uvm_component_utils(mem_sequencer)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

endclass : mem_sequencer
