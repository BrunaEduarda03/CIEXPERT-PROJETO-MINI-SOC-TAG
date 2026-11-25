//-----------------------------------------------------------------------------
// mem_base_seq.sv
// Base das sequences de MEMORY DATA: tarefas do_write()/do_read() para que as
// sequences derivadas pensem em "palavra", nao em item.
//-----------------------------------------------------------------------------
class mem_base_seq extends uvm_sequence #(mem_item);
  `uvm_object_utils(mem_base_seq)

  function new(string name = "mem_base_seq");
    super.new(name);
  endfunction

  task do_write(bit [9:0] addr, bit [31:0] data);
    mem_item t = mem_item::type_id::create("t");
    start_item(t);
    t.mem_i_wr_en = 1'b1;
    t.mem_i_addr  = addr;
    t.mem_i_data  = data;
    finish_item(t);
  endtask

  task do_read(bit [9:0] addr, output logic [31:0] data);
    mem_item t = mem_item::type_id::create("t");
    start_item(t);
    t.mem_i_wr_en = 1'b0;
    t.mem_i_addr  = addr;
    t.mem_i_data  = '0;
    finish_item(t);
    data = t.mem_o_data;   // preenchido pelo mem_driver
  endtask

endclass : mem_base_seq
