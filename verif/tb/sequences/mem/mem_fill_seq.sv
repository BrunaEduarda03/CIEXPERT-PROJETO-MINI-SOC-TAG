//-----------------------------------------------------------------------------
// mem_fill_seq.sv
// Escreve n_words palavras a partir de start_addr com um padrao (ST-MEM-01).
// Com readback=1 le de volta a mesma faixa; os dados escritos e lidos ficam
// em wdata_q/rdata_q para o teste (ou o scoreboard) comparar.
//-----------------------------------------------------------------------------
typedef enum {
  MEM_PAT_ZERO,      // 0x0000_0000
  MEM_PAT_ONES,      // 0xFFFF_FFFF
  MEM_PAT_AA55,      // 0xAAAA_5555
  MEM_PAT_WALK1,     // 1 << (i % 32)
  MEM_PAT_ADDR,      // dado = endereco (detecta aliasing de endereco)
  MEM_PAT_RANDOM
} mem_pattern_e;

class mem_fill_seq extends mem_base_seq;
  `uvm_object_utils(mem_fill_seq)

  rand bit [9:0]     start_addr;
  rand int unsigned  n_words;
  rand mem_pattern_e pattern;
  bit                readback = 1'b1;

  bit [31:0] wdata_q[$];
  logic [31:0] rdata_q[$];

  constraint c_range {
    n_words inside {[1:1024]};
    start_addr + n_words <= 1024;
  }

  function new(string name = "mem_fill_seq");
    super.new(name);
  endfunction

  function bit [31:0] pattern_word(int unsigned i, bit [9:0] addr);
    case (pattern)
      MEM_PAT_ZERO : return 32'h0000_0000;
      MEM_PAT_ONES : return 32'hFFFF_FFFF;
      MEM_PAT_AA55 : return 32'hAAAA_5555;
      MEM_PAT_WALK1: return 32'h1 << (i % 32);
      MEM_PAT_ADDR : return {22'h0, addr};
      default      : return $urandom();
    endcase
  endfunction

  task body();
    logic [31:0] rd;
    wdata_q.delete();
    rdata_q.delete();

    `uvm_info(get_type_name(), $sformatf("fill %s: addr 0x%03h..0x%03h (%0d palavras), readback=%0b",
                                         pattern.name(), start_addr, start_addr + n_words - 1,
                                         n_words, readback), UVM_MEDIUM)

    for (int unsigned i = 0; i < n_words; i++) begin
      bit [31:0] d = pattern_word(i, start_addr + i);
      wdata_q.push_back(d);
      do_write(start_addr + i, d);
    end

    if (readback)
      for (int unsigned i = 0; i < n_words; i++) begin
        do_read(start_addr + i, rd);
        rdata_q.push_back(rd);
      end
  endtask

endclass : mem_fill_seq
