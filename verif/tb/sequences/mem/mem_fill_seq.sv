//-----------------------------------------------------------------------------
// mem_fill_seq.sv
// Escreve n_words palavras a partir de start_addr com um padrao de dados.
// O endereco da a volta em 1023 -> 0 (10 bits). Os valores escritos ficam em
// 'written' para quem quiser ler de volta. E a sequence que dezembro usa para
// carregar os blocos do AES.
//-----------------------------------------------------------------------------
typedef enum {PAT_ZEROS, PAT_ONES, PAT_AA55, PAT_WALK1, PAT_RANDOM} mem_pattern_e;

class mem_fill_seq extends uvm_sequence #(mem_item);
  `uvm_object_utils(mem_fill_seq)

  bit [9:0]     start_addr = 0;
  int unsigned  n_words    = 16;
  mem_pattern_e pattern    = PAT_RANDOM;

  bit [31:0]    written[$];   // saida: dados na ordem de escrita

  function new(string name = "mem_fill_seq");
    super.new(name);
  endfunction

  static function bit [31:0] pattern_word(mem_pattern_e p, int unsigned i);
    case (p)
      PAT_ZEROS: return 32'h0000_0000;
      PAT_ONES:  return 32'hFFFF_FFFF;
      PAT_AA55:  return (i % 2) ? 32'h5555_AAAA : 32'hAAAA_5555;
      PAT_WALK1: return 32'h1 << (i % 32);
      default:   return $urandom();
    endcase
  endfunction

  task body();
    mem_write_seq wr;
    written.delete();
    for (int unsigned i = 0; i < n_words; i++) begin
      wr      = mem_write_seq::type_id::create("wr");
      wr.addr = start_addr + i;          // trunca em 10 bits: da a volta
      wr.data = pattern_word(pattern, i);
      wr.start(m_sequencer, this);
      written.push_back(wr.data);
    end
  endtask

endclass : mem_fill_seq
