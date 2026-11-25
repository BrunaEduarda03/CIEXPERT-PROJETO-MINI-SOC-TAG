// mem_if.sv - fios da interface MEMORY DATA (testbench <-> DUT)
interface mem_if (input logic mem_clk);
  logic [31:0] mem_i_data  = '0;
  logic        mem_i_wr_en = 0;    // 1 = escrita, 0 = leitura
  logic [9:0]  mem_i_addr  = '0;
  logic [31:0] mem_o_data;         // vem do DUT
  logic        tb_valid    = 0;    // so do testbench: 1 = ciclo com transacao real
endinterface
