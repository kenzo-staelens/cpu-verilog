cls
iverilog.exe -o .\out\regfile .\modules\storable\register_file.v .\test\regfile_tb.v
vvp.exe .\out\regfile