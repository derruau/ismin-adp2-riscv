// Cache Direct V3 - Bypass du lag de 1 cycle d'horloge entre le moment où on passe de
// RESPONSE à MEM_QUERRY lors d'un cache miss.
// On passe de 8 cycles à 7 cycles de latence pour un cache miss.
// Je crois que je ne peux pas optimiser ce cache plus que ça au niveau vitesse de réponse.
// Par contre je peux encore simplifier la logique et régler le bug lors du changement
// de valeur de la ligne de cache à la transition MEM_QUERRY vers RESPONSE.

module cache #(
	localparam ByteOffsetBits = 4, // Nombre de bits de l'offset (bits 3 à 0)
	localparam IndexBits = 6, // Nombre de bits de l'index (bits 9 à 4)
	localparam TagBits = 22, // Nombre de bits du tag (bits 31 à 10)
	  
	localparam NrWordsPerLine = (2 ** ByteOffsetBits) / 4, // Le nombre de mots dans chaque ligne
	localparam NrLines = 2 ** IndexBits, // Le nombre de lignes dans le cache
	  
	localparam LineSize = 32 * NrWordsPerLine // Nombre de bits par ligne
) (
    input logic clk_i,
    input logic rstn_i,

    input logic [31:0] addr_i,

    // Read port
    input logic read_en_i,
    output logic read_valid_o,
    output logic [31:0] read_word_o,

    // Memory
    output logic [31:0] mem_addr_o,

    // Memory read port
    output logic mem_read_en_o,
    input logic mem_read_valid_i,
    input logic [LineSize-1:0] mem_read_data_i
);

  // Les états de la machine d'état
  localparam logic [1:0] WAIT         = 2'h0;
  localparam logic [1:0] MEM_QUERRY   = 2'h1;
  localparam logic [1:0] RESPONSE     = 2'h2;

  // Les lignes de registre.
  // Chaque ligne a le format suivant:
  // DIRTY-BIT TAG DATA
  logic [LineSize + TagBits:0] registers [NrLines] = '{default: 0};

  // L'état actuel du cache
  logic [1:0] cache_state = WAIT;
  // L'état du cache au prochain cycle d'horloge.
  // Le but est d'avoir une FSM plus réactive aux changements
  // et surtout de gagner un cycle lors de la transition RESPONSE à MEM_QUERRY
  // lors d'un cache miss (c.f le rapport/les notes)
  logic [1:0] next_cache_state = WAIT;

  // Le signal qui indique si oui ou non la requète est un hit ou un miss
  logic request_hit_w;

  // Les signaux contenant respectivement le tag, l'index et l'offset
  // de l'adresse addr_i
  logic [TagBits-1:0] tag_w;
  logic [IndexBits-1:0] index_w;
  logic [ByteOffsetBits-1:0] offset_w;

  // Décomposition des différentes parties d'une ligne de cache
  logic rdirty_bit_w;
  logic [TagBits-1:0] rtag_w;
  logic [LineSize-1:0] rdata_w;

  // Signal intermédiaire utilisé pour retourner le mot au processeur.
  // C'est le signal qui contient la version bitshiftée de rdata_w.
  logic [LineSize - 1:0] shifted_rdata;

  always_ff @(posedge clk_i or negedge rstn_i) begin
    if (!rstn_i || !read_en_i) begin
      cache_state <= WAIT;
    end else begin
      if (cache_state == MEM_QUERRY && next_cache_state == RESPONSE) begin
        // BUG POSSIBLE: En changeant addr_i soudainement entre un cache 
        // miss et le moment où on update registers on peut mettre 
        // d'autres données dans une autre ligne de cache avec un 
        // mauvais TAG
        registers[index_w] = {1'b1, tag_w, mem_read_data_i};
      end
      cache_state <= next_cache_state;
    end
  end

  always_comb begin
    if (!read_en_i) begin
      next_cache_state = WAIT;
    end else begin
      case (cache_state) 
          WAIT:
            begin
            if (request_hit_w) next_cache_state = RESPONSE;
            else next_cache_state = MEM_QUERRY;
            end

          MEM_QUERRY:
            begin
            if (!mem_read_valid_i) next_cache_state = MEM_QUERRY;
            else begin
              next_cache_state = RESPONSE;
            end
            end
          
          RESPONSE:
            begin
            if (!request_hit_w) next_cache_state <= MEM_QUERRY;	
            end
        endcase
    end
  end

  always_comb begin
    // Assigne le tag, l'index et l'offset à l'addresse d'input
    {tag_w, index_w, offset_w} = addr_i;

    // Assignation de la ligne de cache correspondante
    {rdirty_bit_w, rtag_w, rdata_w} = registers[index_w];
    
    // Condition pour que la requète soit un hit:
    //  - Le dirty bit de la ligne de cache doit être à 1
    //  - Le tag doit correspondre à celui de l'input
    // Si on ne prends pas en compte read_en_i, il y a un bug lorsqu'on désactive
    // puis reactive la lecture.
    request_hit_w = read_en_i && (rdirty_bit_w == 1'b1) && (rtag_w == tag_w);

    // BEHAVIOUR: mem_read_data_i renvoie les données dans le sens inverse, c'est à dire:
    // [INSTRUCTION_3] [INSTRUCTION_2] [INSTRUCTION_1] [INSTRUCTION_0]
    // OBSERVATION: cette solution coute cher car un bitshift d'un nombre inconnu à l'avance
    // doit être implémenté avec un barrel shifter (bcp de multiplexeurs).
    // Il vaudrait serait peut être mieux avoir un case avec seules quelques valeurs
    // d'offset (0, 4, 8 et 12) car on ne prends que des instructions de taille 32 bits
    shifted_rdata = rdata_w >> ('h8 * offset_w);
    
    case (cache_state)
      WAIT: 
        begin
        read_valid_o = 1'b0;
        read_word_o = 32'h0;
        mem_addr_o = 32'h0;
        mem_read_en_o = 1'b0;
        end
      MEM_QUERRY:
        begin
        read_valid_o = 1'b0;
        read_word_o = 32'h0;
        mem_addr_o = {tag_w, index_w, {ByteOffsetBits{1'b0}}};
        mem_read_en_o = 1'b1;
        end
      RESPONSE:
        begin
        read_valid_o = request_hit_w; // Pour éviter de gaspiller un cycle à retourner à WAIT dans un edge case.
        read_word_o = shifted_rdata[31:0];
        mem_addr_o = next_cache_state == MEM_QUERRY ? {tag_w, index_w, {ByteOffsetBits{1'b0}}} :  32'h0;
        mem_read_en_o = next_cache_state == MEM_QUERRY ? 1'b1 : 1'b0;
        end
    endcase
  end

endmodule

// TODO: state transition between RESPONSE & MEM_QUERRY to avoid wasting two states on returning to WAIT.
// Also we need to insta update the state when we go from RESPONSE to cache miss