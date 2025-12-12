# Processador RISC 32-bits (Multiciclo) em FPGA

![Status](https://img.shields.io/badge/Status-Concluído-success)
![Plataforma](https://img.shields.io/badge/FPGA-Altera%20DE2-blue)
![Chip](https://img.shields.io/badge/Cyclone%20II-EP2C35F672C6-red)
![Linguagem](https://img.shields.io/badge/Linguagem-Verilog%20HDL-green)
![Licença](https://img.shields.io/badge/License-MIT-lightgrey)

Implementação de um processador RISC de 32 bits com arquitetura *Load/Store* personalizada (baseada em MIPS), sintetizado e validado na placa de desenvolvimento **Altera DE2**.

Este projeto foi desenvolvido como parte da disciplina **EGM0018 - Projeto e Síntese de Sistemas Digitais**.

---

## 📋 Sobre o Projeto

O objetivo deste projeto foi projetar, codificar (RTL) e sintetizar um processador completo capaz de executar um conjunto de instruções pré-definido. A arquitetura adotada foi a **Multiciclo**, onde cada instrução é dividida em etapas menores (Fetch, Decode, Execute, Memory, WriteBack) para otimizar o uso de recursos.

O sistema utiliza **E/S Mapeada em Memória (Memory Mapped I/O)** para interagir com os periféricos da placa DE2 (Chaves e LEDs) sem a necessidade de instruções de I/O dedicadas.

## ⚙️ Características Técnicas

* **Arquitetura:** RISC 32-bits (Harvard modificado internamente).
* **Datapath:** Multiciclo (5 estados).
* **Clock:** Sistema roda com *Clock Divider* (~3Hz) para visualização humana do fluxo de execução nos LEDs.
* **Memória:** RAM interna de 64 palavras de 32 bits.

### Conjunto de Instruções (ISA)
O processador suporta as seguintes instruções:
* **Aritméticas/Lógicas:** `ADD`, `SUB`, `AND`, `OR`, `SLT` (Set Less Than).
* **Imediatos:** `ADDI`, `ANDI`.
* **Acesso à Memória:** `LW` (Load Word), `SW` (Store Word).
* **Controle de Fluxo:** `BEQ` (Branch Equal), `BNE` (Branch Not Equal), `J` (Jump), `JAL` (Jump and Link), `JR` (Jump Register).

### Mapa de Memória e I/O
| Endereço (Decimal) | Função | Descrição |
| :--- | :--- | :--- |
| `0 - 63` | RAM | Memória de Dados e Instruções |
| `60` | **Entrada** | Leitura das Chaves (`SW[15:0]`) |
| `61` | **Saída** | Escrita nos LEDs Vermelhos (`LEDR[15:0]`) |

---

## 🛠️ Hardware Utilizado

* **Placa:** Altera DE2 Development and Education Board.
* **FPGA:** Cyclone II EP2C35F672C6.
* **Ferramenta de Síntese:** Quartus II 13.0sp1 Web Edition.

---

## 📂 Estrutura do Repositório

```text
.
├── src/                    # Códigos Fonte (Verilog)
│   ├── Processor.v         # Núcleo do processador (Datapath + Controlador)
│   └── TopLevel_DE2.v      # Interface com a placa, Memória e Clock Divider
│
├── quartus_project/        # Arquivos de projeto do Quartus
│   ├── Processador.qpf     # Arquivo principal do projeto
│   └── Processador.qsf     # Atribuição de pinos (Pin Planner)
│
├── docs/                   # Documentação e Diagramas
│   ├── datapath.png        # Diagrama do Caminho de Dados
│   └── fsm_chart.png       # Diagrama da Máquina de Estados
│
└── README.md               # Este arquivo
