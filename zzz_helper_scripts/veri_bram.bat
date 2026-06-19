cls
iverilog.exe -o .\out\bramprog .\modules\storable\bram_program.v .\test\tb_bram.v
vvp.exe .\out\bramprog