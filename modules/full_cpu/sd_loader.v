module sd_card_loader (
    input  wire        clk,          // 100 MHz system clock
    input  wire        rst,          // active-high reset (trigger reload)
    // Pmod MicroSD pins
    output reg         sd_cs,
    output wire        sd_sck,
    output wire        sd_mosi,
    input  wire        sd_miso,
    // BRAM interface (64 KB = 128 sectors * 512 bytes)
    output reg [15:0]  bram_addr,
    output reg [7:0]   bram_din,
    output reg         bram_we,
    output reg         data_ready
);

    // --------------------------------------------------------
    // 1. Clock divider: 400 kHz SPI clock (SCK)
    //    Half-cycle at 100 MHz -> 125 counts
    // --------------------------------------------------------
    localparam DIV_MAX = 124;           // 125 states (0..124)
    reg [6:0] div_cnt;
    wire      half_tick = (div_cnt == DIV_MAX);

    always @(posedge clk) begin
        if (rst)
            div_cnt <= 0;
        else
            div_cnt <= half_tick ? 0 : div_cnt + 1;
    end

    // --------------------------------------------------------
    // 2. Initialisation clock generator (80 SCK cycles with CS high)
    // --------------------------------------------------------
    reg init_sck_en;
    reg init_sck;
    always @(posedge clk) begin
        if (rst)
            init_sck <= 0;
        else if (half_tick && init_sck_en)
            init_sck <= ~init_sck;
    end

    // --------------------------------------------------------
    // 3. SPI Master (byte-oriented)
    //    - Mode 0 (CPOL=0, CPHA=0)
    //    - Shifts out a loaded byte, simultaneously receives one
    // --------------------------------------------------------
    reg        spi_start;
    reg  [7:0] spi_mosi_byte;
    wire       spi_done;
    wire [7:0] spi_miso_byte;

    reg        spi_active;
    reg        spi_sck_r;
    reg        spi_mosi_r;
    reg  [7:0] mosi_shift;
    reg  [7:0] miso_shift;
    reg  [2:0] rise_cnt;        // counts rising edges (0..7)
    reg        spi_phase;       // 0: wait for half_tick -> rising, 1: wait -> falling
    reg        spi_done_r;

    assign spi_done = spi_done_r;
    assign spi_miso_byte = miso_shift;
    assign sd_sck = init_sck_en ? init_sck : spi_sck_r;
    assign sd_mosi = spi_mosi_r;    // idle high already handles init phase

    always @(posedge clk) begin
        if (rst) begin
            spi_active  <= 0;
            spi_sck_r   <= 0;
            spi_mosi_r  <= 1;
            spi_done_r  <= 0;
            spi_phase   <= 0;
        end else begin
            if (!spi_active) begin
                spi_sck_r  <= 0;
                spi_mosi_r <= 1;              // idle high
                if (spi_start) begin
                    spi_active    <= 1;
                    mosi_shift    <= spi_mosi_byte;
                    miso_shift    <= 0;
                    rise_cnt      <= 0;
                    spi_phase     <= 0;
                    spi_done_r    <= 0;
                    spi_mosi_r    <= spi_mosi_byte[7]; // first bit out
                end
            end else begin
                if (half_tick) begin
                    if (spi_phase == 0) begin          // rising edge
                        spi_sck_r  <= 1;
                        miso_shift <= {miso_shift[6:0], sd_miso};
                        rise_cnt   <= rise_cnt + 1;
                        spi_phase  <= 1;
                    end else begin                      // falling edge
                        spi_sck_r  <= 0;
                        mosi_shift <= {mosi_shift[6:0], 1'b0};
                        spi_mosi_r <= mosi_shift[6];    // next bit
                        if (rise_cnt == 8) begin        // after 8 rising edges
                            spi_active <= 0;
                            spi_done_r <= 1;
                        end else begin
                            spi_phase <= 0;
                        end
                    end
                end
            end
        end
    end

    // --------------------------------------------------------
    // 4. Main SD controller state machine
    // --------------------------------------------------------
    localparam POWER_ON          = 5'd0,
               INIT_CLKS         = 5'd1,
               CMD0_SEND_START   = 5'd2,
               SEND_CMD_BYTE     = 5'd3,
               WAIT_TX           = 5'd4,
               WAIT_RX           = 5'd5,
               CMD0_CHECK_R1     = 5'd6,
               CMD8_SEND_START   = 5'd7,
               CMD8_CHECK_R1     = 5'd8,
               CMD8_RECV_R7      = 5'd9,
               CMD8_R7_NEXT      = 5'd10,
               ACMD41_LOOP       = 5'd11,
               CMD55_SEND_START  = 5'd12,
               CMD55_CHECK_R1    = 5'd13,
               ACMD41_SEND_START = 5'd14,
               ACMD41_CHECK_R1   = 5'd15,
               PREP_CMD17        = 5'd16,
               CMD17_SEND_START  = 5'd17,
               CMD17_CHECK_R1    = 5'd18,
               WAIT_TOKEN        = 5'd19,
               WAIT_TOKEN_CHECK  = 5'd20,
               READ_DATA_START   = 5'd21,
               READ_DATA_BYTE    = 5'd22,
               READ_DATA_STORE   = 5'd23,
               READ_CRC1         = 5'd24,
               READ_CRC2         = 5'd25,
               NEXT_SECTOR       = 5'd26,
               DONE_STATE        = 5'd27,
               ERROR_STATE       = 5'd28;

    reg [4:0] state, next_state_after_rx;
    reg [7:0] init_clk_cnt;
    reg [2:0] tx_byte_idx;
    reg [2:0] cmd_sel;          // 0:CMD0, 1:CMD8, 2:CMD55, 3:ACMD41, 4:CMD17
    reg [31:0] block_arg;
    reg [8:0]  data_byte_cnt;   // 0..511
    reg [1:0]  r7_cnt;
    reg [15:0] sector_cnt;      // 0..127

    // Command byte lookup
    reg [7:0] next_byte;
    always @(*) begin
        case (cmd_sel)
            0: case (tx_byte_idx)   // CMD0
                    0: next_byte = 8'h40;
                    1: next_byte = 8'h00;
                    2: next_byte = 8'h00;
                    3: next_byte = 8'h00;
                    4: next_byte = 8'h00;
                    5: next_byte = 8'h95;
                endcase
            1: case (tx_byte_idx)   // CMD8 (arg=0x1AA, CRC=0x87)
                    0: next_byte = 8'h48;
                    1: next_byte = 8'h00;
                    2: next_byte = 8'h00;
                    3: next_byte = 8'h01;
                    4: next_byte = 8'hAA;
                    5: next_byte = 8'h87;
                endcase
            2: case (tx_byte_idx)   // CMD55
                    0: next_byte = 8'h77;
                    1: next_byte = 8'h00;
                    2: next_byte = 8'h00;
                    3: next_byte = 8'h00;
                    4: next_byte = 8'h00;
                    5: next_byte = 8'h01;   // dummy CRC
                endcase
            3: case (tx_byte_idx)   // ACMD41 (HCS=1, arg=0x40000000, CRC=0x77)
                    0: next_byte = 8'h69;
                    1: next_byte = 8'h40;
                    2: next_byte = 8'h00;
                    3: next_byte = 8'h00;
                    4: next_byte = 8'h00;
                    5: next_byte = 8'h77;
                endcase
            4: case (tx_byte_idx)   // CMD17 (argument from block_arg, CRC=0x01)
                    0: next_byte = 8'h51;
                    1: next_byte = block_arg[31:24];
                    2: next_byte = block_arg[23:16];
                    3: next_byte = block_arg[15:8];
                    4: next_byte = block_arg[7:0];
                    5: next_byte = 8'h01;   // dummy CRC
                endcase
            default: next_byte = 8'hFF;
        endcase
    end

    always @(posedge clk) begin
        if (rst) begin
            state          <= POWER_ON;
            sd_cs          <= 1;
            data_ready     <= 0;
            bram_we        <= 0;
            bram_addr      <= 0;
            sector_cnt     <= 0;
            init_sck_en    <= 0;
            spi_start      <= 0;
            cmd_sel        <= 0;
            tx_byte_idx    <= 0;
            next_state_after_rx <= 0;
            init_clk_cnt   <= 0;
            data_byte_cnt  <= 0;
            r7_cnt         <= 0;
        end else begin
            // Default strobes
            bram_we   <= 0;
            spi_start <= 0;   // pulsed only when needed

            case (state)
                POWER_ON: begin
                    sd_cs       <= 1;
                    init_sck_en <= 1;
                    init_clk_cnt<= 0;
                    state       <= INIT_CLKS;
                end

                INIT_CLKS: begin
                    sd_cs <= 1;
                    if (half_tick) begin
                        init_clk_cnt <= init_clk_cnt + 1;
                        if (init_clk_cnt == 160) begin    // 80 full SCK cycles
                            init_sck_en <= 0;
                            sd_cs       <= 0;
                            state       <= CMD0_SEND_START;
                        end
                    end
                end

                // ---- Send command sequence ----
                CMD0_SEND_START: begin
                    cmd_sel     <= 0;
                    tx_byte_idx <= 0;
                    state       <= SEND_CMD_BYTE;
                end
                CMD8_SEND_START: begin
                    cmd_sel     <= 1;
                    tx_byte_idx <= 0;
                    state       <= SEND_CMD_BYTE;
                end
                CMD55_SEND_START: begin
                    cmd_sel     <= 2;
                    tx_byte_idx <= 0;
                    state       <= SEND_CMD_BYTE;
                end
                ACMD41_SEND_START: begin
                    cmd_sel     <= 3;
                    tx_byte_idx <= 0;
                    state       <= SEND_CMD_BYTE;
                end
                CMD17_SEND_START: begin
                    cmd_sel     <= 4;
                    tx_byte_idx <= 0;
                    state       <= SEND_CMD_BYTE;
                end

                SEND_CMD_BYTE: begin
                    spi_mosi_byte <= next_byte;
                    spi_start     <= 1;
                    state         <= WAIT_TX;
                end

                WAIT_TX: begin
                    if (spi_done) begin
                        if (tx_byte_idx < 5) begin
                            tx_byte_idx <= tx_byte_idx + 1;
                            state       <= SEND_CMD_BYTE;
                        end else begin
                            // all bytes sent, now receive response
                            case (cmd_sel)
                                0: begin next_state_after_rx <= CMD0_CHECK_R1;   state <= WAIT_RX; end
                                1: begin next_state_after_rx <= CMD8_CHECK_R1;   state <= WAIT_RX; end
                                2: begin next_state_after_rx <= CMD55_CHECK_R1;  state <= WAIT_RX; end
                                3: begin next_state_after_rx <= ACMD41_CHECK_R1; state <= WAIT_RX; end
                                4: begin next_state_after_rx <= CMD17_CHECK_R1;  state <= WAIT_RX; end
                            endcase
                        end
                    end
                end

                // ---- Receive a byte ----
                WAIT_RX: begin
                    spi_mosi_byte <= 8'hFF;
                    spi_start     <= 1;
                    state         <= next_state_after_rx;   // will pause here until done
                end
                // The actual wait is embedded: we use spi_done in the target state

                CMD0_CHECK_R1: begin
                    if (spi_done) begin
                        if (spi_miso_byte == 8'h01)
                            state <= CMD8_SEND_START;
                        else
                            state <= CMD0_SEND_START;    // retry
                    end
                end

                CMD8_CHECK_R1: begin
                    if (spi_done) begin
                        if (spi_miso_byte == 8'h01) begin
                            r7_cnt <= 0;
                            state  <= CMD8_RECV_R7;
                        end else
                            state <= ERROR_STATE;
                    end
                end

                CMD8_RECV_R7: begin
                    // read 4 bytes (R7 response)
                    spi_mosi_byte <= 8'hFF;
                    spi_start     <= 1;
                    state         <= CMD8_R7_NEXT;
                end
                CMD8_R7_NEXT: begin
                    if (spi_done) begin
                        if (r7_cnt < 3) begin
                            r7_cnt <= r7_cnt + 1;
                            state  <= CMD8_RECV_R7;
                        end else begin
                            state <= ACMD41_LOOP;
                        end
                    end
                end

                ACMD41_LOOP: begin
                    state <= CMD55_SEND_START;
                end

                CMD55_CHECK_R1: begin
                    if (spi_done) begin
                        if (spi_miso_byte == 8'h01)
                            state <= ACMD41_SEND_START;
                        else
                            state <= ACMD41_LOOP;   // retry
                    end
                end

                ACMD41_CHECK_R1: begin
                    if (spi_done) begin
                        if (spi_miso_byte == 8'h00)
                            state <= PREP_CMD17;    // idle cleared
                        else if (spi_miso_byte == 8'h01)
                            state <= ACMD41_LOOP;   // still busy
                        else
                            state <= ACMD41_LOOP;   // retry
                    end
                end

                PREP_CMD17: begin
                    block_arg <= {7'b0, sector_cnt, 9'b0};
                    state     <= CMD17_SEND_START;
                end

                CMD17_CHECK_R1: begin
                    if (spi_done) begin
                        if (spi_miso_byte == 8'h00)
                            state <= WAIT_TOKEN;
                        else
                            state <= PREP_CMD17;    // retry command
                    end
                end

                WAIT_TOKEN: begin
                    spi_mosi_byte <= 8'hFF;
                    spi_start     <= 1;
                    state         <= WAIT_TOKEN_CHECK;
                end
                WAIT_TOKEN_CHECK: begin
                    if (spi_done) begin
                        if (spi_miso_byte == 8'hFE)
                            state <= READ_DATA_START;
                        else
                            state <= WAIT_TOKEN;     // keep looking
                    end
                end

                READ_DATA_START: begin
                    data_byte_cnt <= 0;
                    state         <= READ_DATA_BYTE;
                end

                READ_DATA_BYTE: begin
                    spi_mosi_byte <= 8'hFF;
                    spi_start     <= 1;
                    state         <= READ_DATA_STORE;
                end

                READ_DATA_STORE: begin
                    if (spi_done) begin
                        bram_din  <= spi_miso_byte;
                        bram_we   <= 1;
                        bram_addr <= bram_addr + 1;
                        if (data_byte_cnt < 511) begin
                            data_byte_cnt <= data_byte_cnt + 1;
                            state <= READ_DATA_BYTE;
                        end else begin
                            state <= READ_CRC1;      // done 512 bytes
                        end
                    end
                end

                READ_CRC1: begin
                    spi_mosi_byte <= 8'hFF;
                    spi_start     <= 1;
                    state         <= READ_CRC2;
                end

                READ_CRC2: begin
                    if (spi_done) begin
                        spi_mosi_byte <= 8'hFF;
                        spi_start     <= 1;
                        state         <= NEXT_SECTOR;
                    end
                end

                NEXT_SECTOR: begin
                    if (spi_done) begin
                        if (sector_cnt < 127) begin
                            sector_cnt <= sector_cnt + 1;
                            state      <= PREP_CMD17;
                        end else begin
                            state <= DONE_STATE;
                        end
                    end
                end

                DONE_STATE: begin
                    sd_cs      <= 1;
                    data_ready <= 1;
                    // stay here forever until reset
                end

                ERROR_STATE: begin
                    sd_cs      <= 1;
                    data_ready <= 0;
                    // hang in error
                end

                default: state <= POWER_ON;
            endcase
        end
    end

endmodule
