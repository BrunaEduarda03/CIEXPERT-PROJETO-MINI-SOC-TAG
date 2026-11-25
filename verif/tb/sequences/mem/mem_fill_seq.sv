// mem_fill_seq.sv - escreve n_words palavras seguidas a partir de start_addr
typedef enum {PAT_ZEROS, PAT_ONES, PAT_AA55, PAT_WALK1, PAT_RANDOM} mem_pattern_e;

// Palavra numero i de cada padrao (o teste tambem usa)
function automatic bit [31:0] mem_pattern_word(mem_pattern_e p, int i);
  case (p)
    PAT_ZEROS: return 32'h0000_0000;
    PAT_ONES:  return 32'hFFFF_FFFF;
    PAT_AA55:  return i[0] ? 32'h5555_AAAA : 32'hAAAA_5555;
    PAT_WALK1: return 32'h1 << (i % 32);
    default:   return $urandom();
  endcase
endfunction

class mem_fill_seq extends uvm_sequence #(mem_item);
  `uvm_object_utils(mem_fill_seq)

  bit [9:0]     start_addr;
  int           n_words = 16;
  mem_pattern_e pattern = PAT_RANDOM;

  function new(string name = "mem_fill_seq");
    super.new(name);
  endfunction

  task body();
    mem_write_seq wr;
    for (int i = 0; i < n_words; i++) begin
      wr      = mem_write_seq::type_id::create("wr");
      wr.addr = start_addr + i;      // 10 bits: depois de 1023 volta a 0
      wr.data = mem_pattern_word(pattern, i);
      wr.start(m_sequencer, this);
    end
  endtask
endclass
