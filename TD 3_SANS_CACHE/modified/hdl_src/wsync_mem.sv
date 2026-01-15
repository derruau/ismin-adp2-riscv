//                              -*- Mode: Verilog -*-
// Filename        : wsync_mem.sv
// Description     : SRAM model. Synchonous writing, Asynchronous reading
// Author          : Michel Agoyan
// Created On      : Sun Aug 18 17:29:59 2024
// Last Modified By: michel agoyan
// Last Modified On: Sun Aug 18 17:29:59 2024
// Update Count    : 0
// Status          : Unknown, Use with caution!

module wsync_mem #(
    // La taille de la mémoire en bits
    parameter SIZE = 4096,
    // La valeur du Wait State ou le nombre de cycles de latence?
    parameter WS = 0,
    // Le fichier utilisé pour initialiser la mémoire avec certaines données
    INIT_FILE = "",
  
    localparam SIZE_IN_BYTES = SIZE / 4,
    localparam ADDR_SIZE = $clog2(SIZE_IN_BYTES)
) (
    input  logic                 clk_i,   // Le signal de clock
    input  logic                 we_i,    // Write Enable: Activer ce signal pour écrire dans la mémoire
    input  logic                 re_i,    // Read Enable: Activer ce signal pour lire dans la mémoire
    input  logic [          3:0] ble_i,   // Byte Lane Enable: Chaque bit représente un octet de adresse mémoire.
                                          // Si ble_i = 3'b1011, et qu'on essaie d'écrire
    input  logic [         31:0] d_i,     // Les données à écrire
    input  logic [ADDR_SIZE-1:0] add_i,   // L'adresse des données à lire ou écrire
    output logic [         31:0] d_o,     // Les données de sortie
    output logic                 valid_o  // Si valid_o == 1, les données d_o dont prêt à être
                                          // lues, sinon on doit encore attendre
);

  logic [31:0] mem    [SIZE_IN_BYTES];
  logic [31:0] mask_w;
  logic [31:0] mem_masked_w, data_masked_w, data_w;

  // Compteur simulant le temps d'attente de la mémoire.
  logic [2:0] cnt_r = 0;

  // Le masque qui va être utilisé 
  assign mask_w = {{8{ble_i[3]}}, {8{ble_i[2]}}, {8{ble_i[1]}}, {8{ble_i[0]}}};

  // Lors de l'initialisation du composant, on initialise la mémoire avec des valeurs par défaut
  // D'ailleurs, le fichier zero.hex n'existe pas dans le dossier original...
  initial begin
    if (INIT_FILE == "") $readmemh("../firmware/zero.hex", mem);
    else $readmemh(INIT_FILE, mem);
  end

  // Cette partie définit le mot à écrire 
  assign mem_masked_w = mem[add_i] & ~mask_w;   // définit les bits que l'on veut garder dans la mémoire
  assign data_masked_w = d_i & mask_w;          // définit les bits à écrire
  assign data_w = mem_masked_w | data_masked_w; // data_w définit la nouvelle donnée que l'on va mettre
                                                // à l'adresse mémoire add_i


  // À chaque cycle d'horloge, si on veut écrire dans la mémoire, on y écrit
  always_ff @(posedge clk_i) begin : wmem
    if (we_i == 1'b1) mem[add_i] <= data_w;
  end

  // Si on veut lire la mémoire, on lit ce qui se trouve à
  // l'adresse add_i, le tout masqué
  always_comb begin : rmem
    if (re_i == 1'b1) d_o = mem[add_i] & mask_w;
    else d_o = 0;
  end

  // Machine d'état qui simule un temps d'attente.
  // À chaque cycle d'horloge, on incrémente cnt_r de 1,
  // lorsqu'il est égal à la valeur de WS on met valid_o à 1, 0 sinon.
  // Si on arrête de lire et d'écrire (we_i et re_i = 0), le compteur reset à 0
  always_ff @(posedge clk_i) begin : valid_proc
    if (((re_i == 1'b1) || (we_i == 1'b1)) && (cnt_r != WS)) cnt_r <= cnt_r + 1;
    else if ((cnt_r == WS) && ((re_i == 1'b1) || (we_i == 1'b1))) cnt_r <= 0;
    else if ((re_i == 1'b0) && (we_i == 1'b0)) cnt_r <= 0;
    else cnt_r <= cnt_r;
  end
  assign valid_o = ((cnt_r == WS) && ((re_i == 1'b1) || (we_i == 1'b1))) ? 1'b1 : 1'b0;
endmodule
