//-----------------------------------------------------------------------------
// mem_if.sv
// Interface do VIP MEMORY DATA: exatamente os sinais da interface do DUT
// (minisoc_top), mais mem_clk como porta (o clock continua sendo gerado pelo
// mem_clk_agt, como o rst_if recebe clk).
//
// A interface nao tem handshake: com mem_i_wr_en = 0 TODO ciclo e uma leitura
// (a RAM atualiza mem_o_data com memory[mem_i_addr]). O monitor observa isso
// como e: cada ciclo com wr_en = 0 e uma transacao de leitura.
//
// Sem clocking block nem modport: a temporizacao fica no driver e no monitor.
//   - driver : dirige logo apos a borda de SUBIDA com "<=" (DUT ve na proxima);
//   - monitor: amostra na borda de SUBIDA (le os valores antes do NBA da RAM).
//
// Temporizacao (minisoc_memory.sv): o endereco e amostrado na borda N de
// mem_clk; o dado lido aparece em mem_o_data na mesma borda N (NBA) e e lido
// na borda N+1 (antes do NBA) -> latencia de 1 ciclo (F12).
//-----------------------------------------------------------------------------
interface mem_if (input logic mem_clk);

  logic [31:0] mem_i_data  = '0;
  logic        mem_i_wr_en = 1'b0;   // 1 = escrita, 0 = leitura
  logic [9:0]  mem_i_addr  = '0;
  logic [31:0] mem_o_data;

endinterface : mem_if
