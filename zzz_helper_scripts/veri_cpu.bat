iverilog.exe -o out\cpu .\modules\full_cpu\cpu.v .\modules\custom_clock\* .\modules\custom_exec\* .\modules\storable\* .\modules\helper\* .\test\cpu_tb.v
vvp.exe out\cpu