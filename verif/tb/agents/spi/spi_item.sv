//-----------------------------------------------------------------------------
// spi_item.sv
// Transacao SPI no nivel de registrador: "escreve DATA em ADDR" ou "le ADDR".
// Os campos tem o nome dos campos do frame de 40 bits (minisoc_spi.sv):
//   {RWb, ADDR[5:0], RSV, DATA[31:0]}
// Uma leitura e UM item, embora no fio sejam 2 frames (pedido + NOP): o
// driver esconde o NOP e o monitor junta os dois frames de novo.
// rdata e o dado que voltou pelo MISO (so em leitura); e logic para X aparecer.
//-----------------------------------------------------------------------------
class spi_item extends uvm_sequence_item;

  rand bit        rwb;    // 1 = leitura, 0 = escrita (como o bit RWb do frame)
  rand bit [5:0]  addr;
  rand bit [31:0] data;   // dado escrito (so em escrita)
  logic    [31:0] rdata;  // dado lido    (so em leitura)

  // Por padrao so o mapa de registradores (0x00-0x0F). Desligue com
  // c_addr_mapped.constraint_mode(0) para gerar enderecos nao mapeados.
  constraint c_addr_mapped { addr inside {[6'h00:6'h0F]}; }

  `uvm_object_utils_begin(spi_item)
    `uvm_field_int(rwb,   UVM_DEFAULT)
    `uvm_field_int(addr,  UVM_DEFAULT | UVM_HEX)
    `uvm_field_int(data,  UVM_DEFAULT | UVM_HEX)
    `uvm_field_int(rdata, UVM_DEFAULT | UVM_HEX | UVM_NOCOMPARE)
  `uvm_object_utils_end

  function new(string name = "spi_item");
    super.new(name);
  endfunction

  function string convert2string();
    if (rwb)
      return $sformatf("SPI READ  addr=0x%02h rdata=0x%08h", addr, rdata);
    else
      return $sformatf("SPI WRITE addr=0x%02h data=0x%08h", addr, data);
  endfunction

endclass : spi_item
