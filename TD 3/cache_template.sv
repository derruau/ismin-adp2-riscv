module cache #(
	localparam ByteOffsetBits = 4, // Nombre de bits de l'offset (bits 3 à 0)
	localparam IndexBits = 6, // Nombre de bits de l'index (bits 9 à 4)
	localparam TagBits = 22, // Nombre de bits du tag (bits 31 à 10)
	  
	localparam NrWordsPerLine = (2 ** TagBits) / 4, // Le nombre de mots dans chaque ligne
	localparam NrLines = 2 ** IndexBits, // Le nombre de lignes dans le cache
	  
	localparam LineSize = 32 * NrWordsPerLine, // Nombre de bits par ligne
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

  // Les signaux contenant respectivement le tag, l'index et l'offset
  logic [TagBits:0] tag_w;
  logic [IndexBits:0] index_w;
  logic [ByteOffsetBits:0] offset_w;

  // Les lignes de registre.
  // Chaque ligne a le format suivant:
  //  TAG  DIRTY-BIT  DATA
  logic [LineSize + TagBits + 1:0] registers [NrLines] = '{default: 0};

  // Assigne le tag, l'index et l'offset à l'addresse d'input
  assign {tag_w, index_w, offset_w} = addr_i;

  // Pour l'instant, on va juste
  always_ff @(posedge clk_i, negedge resetn_i) begin
	  if (!resetn_i) begin
			registers = '{0};
      end else begin
            registers[index_w]
      end
  end

/* TODO */

endmodule
