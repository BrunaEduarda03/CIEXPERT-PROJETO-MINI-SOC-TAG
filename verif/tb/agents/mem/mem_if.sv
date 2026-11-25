//-----------------------------------------------------------------------------
// mem_if.sv
// Interface do VIP MEMORY DATA. Todos os sinais sao sincronos a mem_clk, que
// vem do mem_clk_agt (por isso entra como porta, igual ao clk do rst_if).
//
// tb_valid NAO vai ao DUT: a interface MEMORY DATA nao tem sinal de "valid" e,
// com wr_en = 0, todo ciclo e uma leitura. O driver levanta tb_valid apenas
// nos ciclos de transacoes reais, e o monitor so reconstroi esses ciclos.
//-----------------------------------------------------------------------------
interface mem_if (input logic mem_clk);
  logic [31:0] mem_i_data  = '0;
  logic        mem_i_wr_en = 1'b0;   // 1 = escrita, 0 = leitura
  logic [9:0]  mem_i_addr  = '0;
  logic [31:0] mem_o_data;           // dirigido pelo DUT

  logic        tb_valid    = 1'b0;   // somente testbench
endinterface : mem_if
