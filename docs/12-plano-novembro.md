# 12 — Plano de execução do checkpoint de novembro (prazo 30/11/2026)

> **Status:** Partes 1, 2 e 3 (código, Etapas 1–8) ✅ · `make regress` 18/18 PASS.
> Evidências ✅ em `verif/doc/evidencias/novembro/` (ver `instrucao.md`).
> Falta: VPLAN v2 e slides (seção 8). Todo código novo segue as **Regras de código** da seção 5.

**Em uma frase:** em outubro o testbench aprendeu a *ligar* o DUT (clock e
reset). Agora ele precisa aprender a *conversar* com o DUT — pela **MEMORY
DATA** (dados) e pelo **SPI** (configuração) — e a *conferir sozinho* se as
respostas estão certas.

Fontes: Plano de Projeto (seção 5), Block Guide MiniSoC AES (seções 3, 5, 6, 7, 9),
Plano Dia 3, VPLAN v1, RTL (`minisoc_memory.sv`, `minisoc_spi.sv`) e o testbench
do projetista em `frontend/tb/minisoc_top_tb.sv` (tasks `mem_write`, `mem_read`,
`spi_transfer`, `spi_read` — ótima referência de protocolo).

---

## 1. O que o marco pede

| Entregar | Demonstrar na apresentação |
|---|---|
| VIP MEMORY DATA e VIP SPI (clk/rst já feitos) | transações de memória e SPI acontecendo |
| configuração básica do DUT | monitores reconstruindo essas transações |
| VPLAN atualizado (v2) | checagens automáticas (scoreboard / assertion) |
| primeiros testes de interface | **por que** a arquitetura é assim |

Avaliação: entrega técnica 50% · saber explicar 25% · evidências 15% · apresentação 10%.

---

## 2. Onde você está

| Já existe ✅ | Falta ❌ |
|---|---|
| `agents/clk/`, `agents/rst/` (if, cfg, driver, agent, pkg) | `agents/mem/`, `agents/spi/` |
| `env/` com env, env_cfg, env_pkg (só clk + rst) | scoreboards |
| `tests/` com base_test e smoke_test | `sequences/` está vazio |
| `top_tb.sv`, `top_assertions.sv`, `minisoc_probe_if.sv` | MEMORY e SPI no `top_tb` estão **parados** (sinais fixos) |
| Makefile (`TEST`, `SEED`, `WAVES`) | alvo de regressão |
| Evidências de outubro | VPLAN v2 |

---

## 3. Como o testbench vai ficar

```
                         minisoc_base_test
                                │
                           minisoc_env
   ┌──────────┬──────────┬──────┴──────────┬───────────────────┐
ref_clk_agt mem_clk_agt rst_agt       mem_agt (NOVO)       spi_agt (NOVO)
 (driver)    (driver)   (driver)   sqr → driver            sqr → driver
                                         monitor ──┐            monitor ──┐
                                                   ▼                      ▼
                         probe_if ──► mem_scoreboard (NOVO)   spi_scoreboard (NOVO)
                      (MEM_SEL_AES)
```

- **driver** = transforma uma transação ("escreva 0xCAFE no endereço 5") em sinais no fio.
- **monitor** = faz o caminho inverso: olha os fios e reconstrói a transação.
- **scoreboard** = compara o que o monitor viu com o que *deveria* acontecer.
  É aqui que mora a "checagem automática".

---

## 4. Por que esta ordem

1. **Memória primeiro, porque é mais simples e não depende de nada.**
   - Protocolo trivial: 1 ciclo por acesso, sem frames, sem CDC.
   - Depois do reset o DUT já entrega a memória à interface externa
     (`MEM_SEL_AES = 0` é o valor de reset), então dá para escrever e ler
     **sem precisar do SPI**.
   - Você aprende o padrão completo (if → item → cfg → driver → monitor →
     agent → sequence → scoreboard → teste) num caso fácil, e depois só
     repete no SPI.
2. **SPI depois, reaproveitando o padrão.** Mesma estrutura de arquivos, só o
   protocolo é mais elaborado (frame de 40 bits, leitura em 2 frames).
3. **Integração por último.** O teste de *ownership* precisa dos dois VIPs:
   o SPI muda `MEM_SEL_AES` e a memória confere que o acesso externo foi bloqueado.
4. **De dentro para fora**, como no clk/rst (doc 11): cada arquivo só usa o que
   já existe, então **compila a cada passo**.
5. **Algo rodando no fim de cada etapa.** Se o tempo acabar, o que está pronto
   continua demonstrável.

---

## 5. Arquivos, na ordem de criação

Legenda: 🆕 novo · ✏️ existente que muda.

### Regras de código (valem para TODAS as partes)

**Menos código = mais fácil de entender e de explicar na banca.** A Parte 1
(`agents/mem/`) é o modelo: cada arquivo cabe numa tela (≤ 40 linhas; teste ≤ 70).

1. **1–3 linhas de cabeçalho:** o que o arquivo faz. Sem textão.
2. **Comentário só onde não é óbvio** (o *porquê*: `// o DUT ja atendeu na subida`).
3. **Só o que é usado.** Sem campo, contador, opção ou classe "para o futuro".
   Ex.: não há `mem_cfg` — o agente pega a `vif` direto do `config_db`.
4. **Sem `` `uvm_field_* ``**: só `` `uvm_object_utils `` / `` `uvm_component_utils ``
   e `convert2string()` de 1 linha.
5. **Fluxo reto:** `foreach` em array simples, `if/else`, nada de truques.
6. **Um papel por componente:** driver dirige, monitor observa, scoreboard julga,
   teste só gera tráfego.
7. **Sequences de 1 operação** (`*_write_seq`, `*_read_seq`). A leitura copia
   `req.rdata` depois do `finish_item()` — sem `get_response()`.
8. **Erro de dado = `uvm_error`; ambiente quebrado = `uvm_fatal`.** O teste
   falha se o scoreboard não comparou nada.
9. **Etapa pronta =** compila, testes antigos PASS, e uma falha provocada de
   propósito faz o teste dar FAIL.

### PARTE 1 — MEMORY DATA ✅ concluída

> Etapas 1–3 implementadas. `minisoc_mem_rw_test` PASS (seeds 1, 7, 42):
> 290 leituras comparadas, 0 erros. Falha provocada no scoreboard → teste FAIL
> (checker funciona). Código total da Parte 1: ~320 linhas em 12 arquivos. Smoke test continua PASS.
> As tabelas abaixo já refletem o que foi feito.

Regras da interface (Block Guide 3 e 7; RTL `minisoc_memory.sv`):
- tudo síncrono a `mem_clk` (que já vem do seu `mem_clk_agt`);
- `wr_en = 1`: grava `data` em `addr` na borda de subida;
- `wr_en = 0`: lê `addr`; o dado aparece em `mem_o_data` **1 ciclo depois**;
- durante uma escrita, `mem_o_data` **não muda** (mantém a última leitura);
- só vale com `MEM_SEL_AES = 0`; **não tem reset** (conteúdo inicial indefinido).

#### Etapa 1 — VIP de memória

| # | Arquivo | O que contém | Por quê |
|---|---|---|---|
| 1.1 | 🆕 `agents/mem/mem_if.sv` | Porta de entrada `mem_clk` (como o `rst_if` recebe `clk`); fios `mem_i_data[31:0]`, `mem_i_wr_en`, `mem_i_addr[9:0]`, `mem_o_data[31:0]`; e um sinal **`tb_valid`** que *não* vai ao DUT. | É o "conector físico" entre classes UVM e o DUT. O `tb_valid` resolve um problema real: a interface não tem sinal de *valid* — com `wr_en = 0` todo ciclo é uma "leitura". O driver levanta `tb_valid` só nas transações de verdade. |
| 1.2 | 🆕 `agents/mem/mem_item.sv` | `op` (READ/WRITE), `addr[9:0]`, `data[31:0]`, `rdata[31:0]`; `convert2string()` para o log. | Define *a palavra* com que teste, driver, monitor e scoreboard conversam. Pensar em "escreva X no endereço Y", e não em bits, é a abstração central do UVM. |
| 1.3 | ~~`agents/mem/mem_cfg.sv`~~ | **Removido** (regra 3): só carregaria a `vif`. O agente lê `virtual mem_if` direto do `config_db`. | Menos um arquivo para entender. |
| 1.4 | 🆕 `agents/mem/mem_driver.sv` | Na **descida** de `mem_clk` coloca endereço/dado/`wr_en`/`tb_valid = 1`; na leitura espera a subida seguinte e captura `mem_o_data` em `rdata`. Ocioso: `wr_en = 0`, `tb_valid = 0`. | Mudar na descida e o DUT ler na subida evita corrida de sinais (o mesmo truque da `mem_write` do projetista). |
| 1.5 | 🆕 `agents/mem/mem_monitor.sv` | Na subida de `mem_clk`, se `tb_valid = 1`: escrita → publica; leitura → espera 1 ciclo, pega `mem_o_data` e publica no `analysis_port`. Funciona porque o driver sempre deixa 1 ciclo livre após cada acesso. | O scoreboard **não pode** confiar no driver (o driver pode estar errado). O monitor olha só os fios — é a testemunha independente. |
| 1.6 | 🆕 `agents/mem/mem_agent.sv` | Lê a `vif` do `config_db`, cria sequencer (`typedef uvm_sequencer #(mem_item)`) + driver + monitor, entrega a `vif` a eles e liga driver ↔ sequencer. Sempre ativo. | Empacota o VIP: o env cria **um** objeto e recebe tudo. |
| 1.7 | 🆕 `agents/mem/mem_pkg.sv` | `package` que inclui item, driver, monitor e agent. | Igual ao `clk_pkg`: um `import` e tudo fica visível. |
| 1.8 | ✏️ `top_tb.sv` | Troca os `logic` fixos de memória por `mem_if mem_if_i(.mem_clk(mem_clk_if.clk))` e publica `mem_vif` no `config_db`. | Sem isso o driver não tem fio onde mexer. |
| 1.9 | ✏️ `env/minisoc_env_cfg.sv`, `env/minisoc_env.sv`, `env/minisoc_env_pkg.sv`, `tests/minisoc_base_test.sv` | `mem_vif` no env_cfg, `mem_agt` no env (recebe a `vif` pelo `config_db`), `import mem_pkg`, base_test busca `mem_vif`. | O mesmo caminho que o `vif` do clock percorre hoje (doc 11, seção 3). |
| 1.10 | ✏️ `Makefile` | `+incdir+` e fontes de `agents/mem/`. | O VCS precisa saber dos arquivos novos. |

✅ **Pronto quando:** `make compile` passa e o smoke test continua PASS.

#### Etapa 2 — Sequences de memória + primeiro teste

| # | Arquivo | O que contém | Por quê |
|---|---|---|---|
| 2.1 | 🆕 `sequences/mem/mem_write_seq.sv` | Recebe `addr`, `data`; manda 1 WRITE. | Bloco básico. |
| 2.2 | 🆕 `sequences/mem/mem_read_seq.sv` | Recebe `addr`; manda 1 READ e devolve `rdata`. O driver preenche `req.rdata` antes do `item_done()`, então a sequence só copia depois do `finish_item()` (sem `get_response()`). | O outro bloco básico; a resposta volta para quem pediu, sem fila de respostas para encher. |
| 2.3 | 🆕 `sequences/mem/mem_fill_seq.sv` | Escreve N palavras a partir de um endereço com um padrão: 0, `0xFFFFFFFF`, `0xAAAA5555`, walking-1, aleatório. A função `mem_pattern_word()` fica fora da classe para o teste também usar. | É exatamente o que dezembro vai usar para carregar os blocos do AES. |
| 2.4 | 🆕 `sequences/minisoc_seq_pkg.sv` | `package` com as sequences (memória agora, SPI depois). | Segue a estrutura do Plano Dia 3 (`sequences/mem/`, `spi/`, `virtual/`). |
| 2.5 | 🆕 `tests/minisoc_mem_rw_test.sv` | **T-MEM-RW (parte 1):** (1) limites 0, 1, 511, 512, 1022, 1023 com cada padrão; (2) blocos de 32 palavras por padrão, lidos de volta (o aleatório começa em 1008 e atravessa 1023 → 0); (3) 100 endereços aleatórios, escreve e lê. O endereço tem 10 bits (palavras 0–1023), por isso não existe 4k. `check_phase` falha se o scoreboard não comparou nada. | Primeiro teste de interface. Roda sem SPI, porque `MEM_SEL_AES = 0` após o reset. |
| 2.6 | ✏️ `tests/minisoc_test_pkg.sv`, `Makefile` | Inclui o teste e o pacote de sequences. | Registro na factory para `+UVM_TESTNAME` encontrar. |

✅ **Pronto quando:** o monitor imprime as escritas e leituras no log com os valores certos.

#### Etapa 3 — Checagem local da memória

| # | Arquivo | O que contém | Por quê |
|---|---|---|---|
| 3.1 | 🆕 `env/mem_scoreboard.sv` | Um array associativo que imita a RAM. Escrita com `MEM_SEL_AES = 0` → atualiza; com `MEM_SEL_AES = 1` → **não** atualiza. Leitura de endereço já escrito → compara e dá `UVM_ERROR` se divergir; nunca escrito → ignora. Com `MEM_SEL_AES = 1` leituras externas também são ignoradas. `MEM_SEL_AES` vem do `probe_if`. `report_phase`: "N leituras comparadas, M erros". | É a "checagem local" que o marco pede. Sem ela o teste só *mostra* valores; com ela, o teste *julga*. Já nasce pronto para o ownership (Etapa 7). |
| 3.2 | ✏️ `env/minisoc_env.sv` | Cria `mem_scb`, liga `mem_agt.mon.ap → mem_scb`, entrega o `probe_vif`. | É o fio de dados entre a testemunha (monitor) e o juiz (scoreboard). |

✅ **Pronto quando:** T-MEM-RW passa com o scoreboard ativo e 0 erros.

---

### PARTE 2 — SPI ✅ concluída

> Etapas 4–6 implementadas (~350 linhas em 9 arquivos novos). Seeds 1, 7, 42:
> `minisoc_rst_default_test` PASS (16 leituras, `VERSION = 0x0001_0100` lido pelo SPI)
> e `minisoc_spi_reg_test` PASS (114 leituras comparadas, 0 erros). Smoke e
> T-MEM-RW continuam PASS. Falhas provocadas: reset errado de NUM_BLOCKS no
> espelho → T-RST-DEFAULT FAIL; máscara errada de NUM_BLOCKS → T-SPI-REG FAIL.
> As tabelas abaixo já refletem o que foi feito.

Regras do protocolo (Block Guide 5; RTL `minisoc_spi.sv`):
- frame de **40 bits**, MSB primeiro: `{RWb, ADDR[5:0], RSV=0, DATA[31:0]}`;
- **Mode 0:** `sclk` parado em 0; MOSI muda com `sclk` baixo; o DUT lê na **subida**;
- **escrita** = 1 frame (`RWb = 0`);
- **leitura** = 2 frames: pedido (`RWb = 1`, endereço) + frame NOP
  (`RWb = 0`, endereço `0x3F`). O dado sai no MISO durante o NOP, bits [31:0];
- `sclk` ≤ 25 MHz → padrão 20 MHz (meio período de 25 ns); intervalo entre frames
  para a sincronização interna (CDC).

#### Etapa 4 — VIP SPI

| # | Arquivo | O que contém | Por quê |
|---|---|---|---|
| 4.1 | 🆕 `agents/spi/spi_if.sv` | `sclk`, `cs_n`, `mosi`, `miso`; repouso `cs_n = 1`, `sclk = 0`. | Conector físico, como o `mem_if`. |
| 4.2 | 🆕 `agents/spi/spi_item.sv` | `op` (WRITE/READ), `addr[5:0]`, `data[31:0]`, `rdata[31:0]`; `convert2string()`. | A "palavra" do SPI: "ler o registrador X". |
| 4.3 | ~~`agents/spi/spi_cfg.sv`~~ | **Removido** (regra 3), como o `mem_cfg`. Os tempos ficam no driver: `half = 25ns` (20 MHz) e `gap = 20ns`. | Ninguém muda esses valores hoje; um arquivo a menos. |
| 4.4 | 🆕 `agents/spi/spi_driver.sv` | Task `transfer(tx40, rx40)` (como a `spi_transfer` do projetista). WRITE chama 1 vez; READ chama 2 vezes e guarda `rx[31:0]` em `req.rdata` antes do `item_done()` (mesmo esquema do `mem_driver`, regra 7). | É quem "fala SPI" e **esconde o frame NOP** do teste. O Plano Dia 3 citava `put_response`; trocado pelo padrão mais simples da memória. |
| 4.5 | 🆕 `agents/spi/spi_monitor.sv` | Na subida de `sclk` guarda MOSI e MISO; na subida de `cs_n` fecha o frame. Frame ≠ 40 bits → `uvm_warning` "abortado". Pedido de leitura fica pendente e é completado com o MISO do frame seguinte; frames NOP (`0x3F`) não viram transação. Publica no `analysis_port`. | Testemunha independente. Juntar os 2 frames mantém a abstração do lado de quem observa. |
| 4.6 | 🆕 `agents/spi/spi_agent.sv` | Sequencer + driver + monitor. | Igual ao `mem_agent`. |
| 4.7 | 🆕 `agents/spi/spi_pkg.sv` | Pacote com item, driver, monitor e agent. | — |
| 4.8 | ✏️ `top_tb.sv`, `env/*`, `tests/minisoc_base_test.sv`, `Makefile` | Mesmo roteiro da 1.8–1.10: `spi_if` no top_tb (substitui os `logic` fixos), `spi_vif` no env_cfg, `spi_agt` no env. | — |

✅ **Pronto quando:** `make compile` passa e os testes anteriores continuam PASS.

#### Etapa 5 — Sequences SPI + teste de reset

| # | Arquivo | O que contém | Por quê |
|---|---|---|---|
| 5.1 | 🆕 `sequences/spi/spi_write_seq.sv` | `addr`, `data` → 1 WRITE. | Bloco básico. |
| 5.2 | 🆕 `sequences/spi/spi_read_seq.sv` | `addr` → 1 READ, devolve `rdata`. | Bloco básico. |
| 5.3 | ✏️ `sequences/minisoc_seq_pkg.sv` | Inclui as sequences SPI. | — |
| 5.4 | 🆕 `tests/minisoc_rst_default_test.sv` | **T-RST-DEFAULT:** após o reset, lê 0x00–0x0F pelo SPI e imprime cada valor. O `spi_scoreboard` compara; `check_phase` exige 16 comparações. | Prova que o SPI funciona de ponta a ponta e que o DUT sai do reset com os valores da spec. |

✅ **Pronto quando:** o log mostra `VERSION = 0x0001_0100` lido pelo SPI.

#### Etapa 6 — Checagem local do SPI

| # | Arquivo | O que contém | Por quê |
|---|---|---|---|
| 6.1 | 🆕 `env/spi_scoreboard.sv` | Um "espelho" dos 16 registradores. WRITE → atualiza (respeitando máscaras e read-only); READ → compara e dá `UVM_ERROR` se divergir. Status (0x0C, 0x0F) vêm do hardware: o esperado é lido do `probe_if`. Quando `rst_n` cai, o espelho volta aos valores de reset. `report_phase` com o total. | Checagem local do SPI. |
| 6.2 | ✏️ `env/minisoc_env.sv` | Cria `spi_scb` e liga `spi_agt.mon.ap → spi_scb`. | — |
| 6.3 | 🆕 `tests/minisoc_spi_reg_test.sv` | **T-SPI-REG:** para 0x00–0x0F, 0x10, 0x20 e 0x3E: escreve e lê de volta 0, `0xFFFFFFFF`, `0xA5A5A5A5`, `0x1`, `0x80000000` e um aleatório. | Exercita todas as regras do espelho. |

Regras do espelho (lidas no RTL):

| Endereço | Registro | Reset | Leitura |
|---|---|---|---|
| 0x00–0x09 | KEY, IV, COUNTER | 0 | 32 bits, o que foi escrito |
| 0x0A | NUM_BLOCKS | 1 | só bits [8:0] |
| 0x0B | AES_CONTROL | 0 | bits [4:1] (MODE, DECRYPT); **START sempre lê 0** |
| 0x0C | AES_STATUS | 0 | read-only |
| 0x0D | VERSION | `0x0001_0100` | read-only, constante |
| 0x0E | SYSTEM_CONTROL | `0b1100` | bits [3:0]: `PLL_DIV_SEL`, `PLL_ENABLE`, `MEM_SEL_AES` |
| 0x0F | SYSTEM_STATUS | 0 | read-only (`PLL_LOCKED`) |
| 0x10–0x3E | não mapeados | — | lê 0, escrita ignorada |

> **Cuidado no T-SPI-REG:** escrever `START = 1` ou `PLL_ENABLE = 1` dispara
> comportamento no DUT. O teste escreve `AES_CONTROL` sempre com `START = 0` e,
> em `SYSTEM_CONTROL`, mantém `PLL_ENABLE = 0` (o PLL é testado na Etapa 7).
> **Consequência:** a regra "START sempre lê 0" ainda não é exercitada
> (confirmado com falha provocada). Ela entra na Etapa 7 / dezembro, quando
> START = 1 for escrito de propósito.

✅ **Pronto quando:** T-RST-DEFAULT e T-SPI-REG passam com 0 erros.

---

### PARTE 3 — Integração e configuração do DUT ✅ concluída

> `make regress`: 6 testes × 3 seeds = **18/18 PASS**. Falha provocada no
> `spi_driver` (sclk a 33 MHz) → A-09 dispara e o teste dá FAIL.
> **Bug real encontrado (OPEN-01):** desligar o PLL pelo SPI deixa `sys_rst_n = 1`
> com `PLL_LOCKED = 0` (o `sys_reset_pipe` só limpa numa borda de `sys_clk`, que
> já parou). A-02a dispara. Reproduzido por `minisoc_pll_reenable_test`, que fica
> **fora da regressão** até o RTL ser corrigido. Levar ao projetista.

#### Etapa 7 — Configuração básica + ownership

| # | Arquivo | O que contém | Por quê |
|---|---|---|---|
| 7.1 | 🆕 `sequences/minisoc_cfg_seq.sv` | Via SPI: lê `VERSION` → escreve `PLL_DIV_SEL` + `PLL_ENABLE = 1` → lê `SYSTEM_STATUS` em loop até `PLL_LOCKED = 1` (com **limite de tentativas** → `UVM_FATAL`) → ajusta `MEM_SEL_AES`. | É o item "configuração básica do DUT": passos 1–10 do modelo de programação (Block Guide 9). Em dezembro só se acrescenta "START → esperar DONE". |
| 7.2 | 🆕 `tests/minisoc_pll_bringup_test.sv` | **T-PLL-BRINGUP:** roda 7.1 nos 4 divisores e **mede o `sys_clk`** pelo probe (500, 1000, 2000, 4000 ps). Entre um divisor e outro aplica **reset** (desligar o PLL expõe o OPEN-01). | Mostra o DUT sendo configurado de verdade. O limite evita simulação travada se o PLL nunca travar. |
| 7.2b | 🆕 `tests/minisoc_pll_reenable_test.sv` | **T-PLL-REENABLE (OPEN-01):** liga, desliga e religa o PLL pelo SPI. **Hoje FALHA** (A-02a). | Prova o bug com um teste de 30 linhas; vira PASS quando o RTL for corrigido. |
| 7.3 | 🆕 `tests/minisoc_mem_owner_test.sv` | **T-MEM-OWNER:** grava 3 endereços pela memória; `minisoc_cfg_seq` com `MEM_SEL_AES = 1` (PLL travado); tenta gravar `0xDEAD…`; devolve a memória (`MEM_SEL_AES = 0`) e lê: **o valor antigo continuou lá**. Teste separado para o T-MEM-RW continuar sem SPI (regra 5). | Junta os dois VIPs num teste só (REQ-MEM-03: um dono por vez). É o caminho de dezembro: SPI configura, memória carrega/lê. |

✅ **Pronto quando:** `PLL_LOCKED = 1` nos 4 divisores e T-MEM-OWNER passa.

#### Etapa 8 — Assertions e regressão

| # | Arquivo | O que contém | Por quê |
|---|---|---|---|
| 8.1 | ✏️ `top_assertions.sv` | **A-09:** com `cs_n = 0`, período de `sclk` ≥ 40 ns. **A-10:** com `MEM_SEL_AES = 0`, endereço/dado/`wr_en` sem X/Z na subida de `mem_clk`. | Checagem com pouco código. A-09 vigia o *próprio* testbench. |
| 8.2 | ✏️ `Makefile` | `make regress`: compila uma vez, roda 6 testes × seeds 1, 2, 3, imprime a tabela e grava `sim/logs/regress.txt`. | Evidência fácil; a regressão só é exigida em dezembro, então é ponto a favor. |
| 8.3 | *(não feito)* `tests/minisoc_spi_abort_test.sv` | **T-SPI-ABORT:** frames interrompidos no meio. Precisaria de um modo "frame parcial" no driver; fica para dezembro. O monitor já avisa frame abortado. | Opcional. |

### Fica para dezembro (registrar no VPLAN v2)

Monitor/checker completo do PLL (janela de lock), virtual sequencer, covergroups,
tudo do AES (monitor, refmod, scoreboard), T-SPI-ABORT, a regra "START sempre
lê 0" e a correção/reteste do OPEN-01.

---

## 6. Resumo

**27 arquivos novos · 8 alterados** (`top_tb`, `env_cfg`, `env`, `env_pkg`,
`base_test`, `test_pkg`, `Makefile`, `top_assertions`).

| Teste | Etapa | Verifica | Checker |
|---|---|---|---|
| `minisoc_smoke_test` | — | clock + reset (já existe) | SVA A-01 |
| `minisoc_mem_rw_test` | 2–3 | memória (sem SPI) | mem_scoreboard |
| `minisoc_rst_default_test` | 5 | valores de reset via SPI | spi_scoreboard |
| `minisoc_spi_reg_test` | 6 | todos os registradores | spi_scoreboard |
| `minisoc_pll_bringup_test` | 7 | PLL trava e `sys_clk` certo nos 4 divisores | medição + SVA |
| `minisoc_mem_owner_test` | 7 | um dono por vez (REQ-MEM-03) | mem_scoreboard |
| `minisoc_pll_reenable_test` | 7 | OPEN-01 — **hoje FALHA** (fora da regressão) | SVA A-02a |

**Prioridade se o tempo acabar:** Etapas 1–3 (memória) → 4–6 (SPI) → 7 → 8.
Memória + SPI com scoreboard é o núcleo; o resto é bônus.

---

## 7. Decisões de arquitetura (o que a banca vai perguntar)

| Decisão | Por quê |
|---|---|
| Memória antes do SPI | Protocolo mais simples e independente (`MEM_SEL_AES = 0` no reset); serve de modelo para o SPI. |
| MEM e SPI têm sequencer; clk/rst não | MEM/SPI têm transações com conteúdo e ordem; clock e reset são só parâmetros. |
| `tb_valid` no `mem_if` | A interface não tem *valid*; sem ele o monitor veria "leituras fantasmas" todo ciclo. |
| Leitura SPI é 1 item, mas são 2 frames | Abstração: o teste pensa em registrador; driver e monitor cuidam do protocolo. |
| clk/rst como *agents* (o Dia 3 dizia "só driver") | Padrão uniforme, reuso (2 `clk_agent`) e fácil tornar passivo. |
| Scoreboard próprio, sem RAL | 16 registros, prazo curto, controle total das regras. RAL é evolução futura. |
| `MEM_SEL_AES` lido do `probe_if` | Sinal interno; o scoreboard precisa saber quem é o dono no instante do acesso. |
| `UVM_ERROR` × `UVM_FATAL` | Dado errado = ERROR (continua achando mais). Ambiente quebrado / timeout = FATAL. |

---

## 8. Depois do código: VPLAN v2, evidências, apresentação

**VPLAN v2** (`verif/doc/CI-Expert_Fase2_Verification_Plan_v2.docx`): versão
V2.0; VCS `X-2025.06-SP2` e `UVM-1.2`; diagrama novo; decisões da seção 7;
F01, F08, F09, F12, F13 (e F05) → `IMPLEMENTADO` com o log; OPEN-03 fechado
com o `VERSION` lido; lista do que foi para dezembro.

**Evidências** (`verif/doc/evidencias/novembro/`): logs com `TEST PASSED`;
saída do `make regress`; print do Verdi de uma escrita/leitura na memória e de
um WRITE e um READ SPI; trecho do scoreboard ("N comparadas, 0 erros"); **uma
falha provocada de propósito** (prova de que o scoreboard não está "dormindo").

**Slides (6–8):** outubro → novembro · arquitetura · VIP MEMORY · VIP SPI ·
checagens · configuração do DUT + ownership · testes + regressão + VPLAN ·
plano de dezembro.

---

## 9. Aprovação

Marque cada item. Os marcados "Ajustar" eu reescrevo antes de começar.

| # | Decisão | Aprovo | Ajustar |
|---|---|---|---|
| 1 | Tudo hoje, numa sessão, na ordem das Etapas 1 → 8 | [ ] | [ ] |
| 2 | Memória (Etapas 1–3) antes do SPI (4–6); integração por último (7) | [ ] | [ ] |
| 3 | `tb_valid` no `mem_if` para o monitor da memória | [ ] | [ ] |
| 4 | Scoreboard próprio de registradores, sem RAL | [ ] | [ ] |
| 5 | Sequences em `sequences/` com pacote próprio `minisoc_seq_pkg` | [ ] | [ ] |
| 6 | Checker completo do PLL vai para dezembro (registrado no VPLAN v2) | [ ] | [ ] |
| 7 | **Modo de execução:** ao fim de cada etapa eu rodo `make compile run`, te mostro o resultado e deixo tudo *staged* para você revisar — sem commit/push meu | [ ] | [ ] |

**Decisão final:** [ ] Aprovo a execução do plano  [ ] Não aprovo / ajustar antes
