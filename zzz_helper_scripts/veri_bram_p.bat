cls
iverilog.exe -o .\out\bram_persist .\modules\storable\bram_persistent.v .\test\tb_bram_persist.v
vvp.exe .\out\bram_persist