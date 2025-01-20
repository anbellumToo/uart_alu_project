
read_verilog rtl/uart_mod.sv
read_verilog -sv rtl/uart_alu.sv

read_verilog third_party/alexforencich_uart/rtl/uart_rx.v
read_verilog third_party/alexforencich_uart/rtl/uart_tx.v

prep -top uart_alu                 # Set uart_alu as the top-level module
opt -full                          # Perform full optimization
stat                               # Display statistics

write_verilog -noexpr -noattr -simple-lhs synth/netlist.v
