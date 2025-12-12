module Processor (
    input wire clk,
    input wire reset,
    output reg [31:0] mem_addr,
    output reg [31:0] mem_wdata,
    input wire [31:0] mem_rdata,
    output reg mem_wen,
    output wire [7:0] pc_debug,
    output wire [2:0] state_debug
);

    // Estados
    localparam FETCH=0, DECODE=1, EXEC=2, MEM=3, WRITEBACK=4;
    reg [2:0] state, next_state;

    // Debug
    assign pc_debug = PC[7:0];
    assign state_debug = state;

    // Registradores
    reg [31:0] PC, IR, MDR, A, B, ALUOut;
    reg [31:0] RegFile [0:15];
    
    // Decodificação
    wire [5:0] opcode = IR[31:26];
    wire [4:0] rs = IR[25:21];
    wire [4:0] rt = IR[20:16];
    wire [4:0] rd = IR[15:11];
    wire [15:0] imm = IR[15:0];
    wire [31:0] sign_ext_imm = {{16{imm[15]}}, imm};
    wire [25:0] jump_addr = IR[25:0];

    // --- Datapath Sequencial ---
    integer i;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i=0; i<16; i=i+1) RegFile[i] <= 0;
            PC <= 0;
            state <= FETCH;
            MDR <= 0;
        end else begin
            RegFile[0] <= 0; // R0 constante 0
            state <= next_state;
            
            if (state == FETCH)  IR <= mem_rdata; 
            if (state == DECODE) begin A <= RegFile[rs]; B <= RegFile[rt]; end
            if (state == MEM)    MDR <= mem_rdata; 
            
            if (state == DECODE && opcode == 6'h03) RegFile[15] <= PC; 

            if (state == WRITEBACK) begin
                if (opcode == 6'h00) RegFile[rd] <= ALUOut;
                else if (opcode == 6'h23) RegFile[rt] <= MDR;
                else if (opcode[5:3] == 3'b001) RegFile[rt] <= ALUOut;
            end
            
            if (state == FETCH) PC <= PC + 1;
            else if (state == EXEC) begin
               if (opcode == 6'h04 && A == B) PC <= PC + sign_ext_imm;
               if (opcode == 6'h05 && A != B) PC <= PC + sign_ext_imm;
               if (opcode == 6'h02) PC <= jump_addr;
               if (opcode == 6'h03) PC <= jump_addr;
               if (opcode == 6'h00 && IR[5:0] == 6'h08) PC <= A;
            end
        end
    end

    // --- ALU ---
    reg [31:0] ALUResult;
    reg [31:0] Operand2;
    always @(*) begin
        if (state == EXEC && (opcode[5:3] == 3'b001 || opcode == 6'h23 || opcode == 6'h2B)) 
            Operand2 = sign_ext_imm;
        else 
            Operand2 = B;

        case (opcode)
            6'h00: begin // R-Type
                case (IR[5:0]) 
                    6'h20: ALUResult = A + Operand2; 
                    6'h22: ALUResult = A - Operand2; 
                    6'h24: ALUResult = A & Operand2; 
                    6'h25: ALUResult = A | Operand2; 
                    6'h2A: ALUResult = (A < Operand2) ? 1 : 0; 
                    default: ALUResult = 0;
                endcase
            end
            6'h08: ALUResult = A + Operand2; 
            6'h0C: ALUResult = A & Operand2; 
            6'h23: ALUResult = A + Operand2; // LW Address Calc
            6'h2B: ALUResult = A + Operand2; // SW Address Calc
            default: ALUResult = 0;
        endcase
    end

    always @(posedge clk) if (state == EXEC || state == DECODE) ALUOut <= ALUResult;

    // --- Controlador (FSM) ---
    always @(*) begin
        mem_wen = 0;
        mem_addr = PC;
        mem_wdata = B; 
        
        case (state)
            FETCH: begin mem_addr = PC; next_state = DECODE; end
            
            // --- CORREÇÃO: Todos vão para EXEC primeiro ---
            DECODE: next_state = EXEC; 
            
            EXEC: begin
                // Aqui decidimos: LW/SW vai pra MEM, o resto pra WB ou Fetch
                if (opcode == 6'h23 || opcode == 6'h2B) next_state = MEM;
                else if (opcode == 6'h00 || opcode[5:3] == 3'b001) next_state = WRITEBACK;
                else next_state = FETCH;
            end
            
            MEM: begin
                mem_addr = ALUOut; 
                if (opcode == 6'h2B) begin mem_wen = 1; next_state = FETCH; end 
                else next_state = WRITEBACK; 
            end
            
            WRITEBACK: next_state = FETCH;
            default: next_state = FETCH;
        endcase
    end
endmodule