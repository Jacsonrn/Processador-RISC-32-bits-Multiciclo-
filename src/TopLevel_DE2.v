module TopLevel_DE2 (
    input wire CLOCK_50,
    input wire [0:0] KEY,      // Reset
    input wire [15:0] SW,      // Switches
    output wire [15:0] LEDR    // LEDs
);

    // --- Clock Lento ---
    reg [25:0] counter;
    always @(posedge CLOCK_50) counter <= counter + 1;
    wire slow_clk = counter[24]; 

    wire reset = ~KEY[0]; 

    // Sinais do Processador
    wire [31:0] cpu_addr, cpu_wdata, cpu_rdata;
    wire cpu_wen;
    wire [7:0] pc_to_led;
    wire [2:0] state_to_led;

    Processor CPU (
        .clk(slow_clk),
        .reset(reset),
        .mem_addr(cpu_addr),
        .mem_wdata(cpu_wdata),
        .mem_rdata(cpu_rdata),
        .mem_wen(cpu_wen),
        .pc_debug(pc_to_led),    
        .state_debug(state_to_led) 
    );

    reg [31:0] RAM [0:63]; 
    reg [15:0] led_reg;

    // --- PROGRAMA NOVO (Endereços Simplificados) ---
    initial begin
        led_reg = 16'h0000; // Começa APAGADO para testar se acende
        
        // 0: LW R1, 60(R0)   -> Lê SW (Endereço 60)
        // Imediato 60 = 0x3C. Opcode LW = 0x23.
        RAM[0] = {6'h23, 5'd0, 5'd1, 16'd60}; 
        
        // 1: ADDI R1, R1, 1  -> Soma 1
        RAM[1] = {6'h08, 5'd1, 5'd1, 16'd1};   
        
        // 2: SW R1, 61(R0)   -> Escreve LED (Endereço 61)
        // Imediato 61 = 0x3D. Opcode SW = 0x2B.
        RAM[2] = {6'h2B, 5'd0, 5'd1, 16'd61}; 
        
        // 3: J 0             -> Reinicia
        RAM[3] = {6'h02, 26'd0};               
    end

    // --- Leitura (Combinacional) ---
    // Endereço 60 (d60) lê as chaves
    assign cpu_rdata = (cpu_addr == 32'd60) ? {16'b0, SW} : 
                       (cpu_addr < 60)      ? RAM[cpu_addr] : 
                       32'd0;

  // --- Lógica de Escrita ---
    // Voltamos para o clock lento (na borda de descida), pois é lá que os dados
    // do processador (addr, wdata, wen) são garantidos de estarem estáveis.
    always @(negedge slow_clk) begin
        if (cpu_wen) begin
            // Endereço 61 (d61) escreve nos LEDs
            if (cpu_addr == 32'd61) begin
                led_reg <= cpu_wdata[15:0]; 
            end
            // Escrita na RAM
            else if (cpu_addr < 60) begin
                RAM[cpu_addr] <= cpu_wdata;
            end
        end
    end

    // Saída Visual
    assign LEDR[7:0]  = pc_to_led;      // PC piscando
    assign LEDR[15:8] = led_reg[7:0];   // Resultado da soma

endmodule