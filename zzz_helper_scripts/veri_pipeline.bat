cls
iverilog.exe -o out\pipeline .\modules\custom_exec\pipeline_unit.v .\modules\helper\* .\test\pipeline_tb.v
C:\iverilog\bin\vvp.exe .\out\pipeline