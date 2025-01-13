read_verilog rtl/uart_top.sv
read_verilog rtl/pll.sv
read_verilog rtl/uart_mod.sv

read_verilog third_party/alexforencich_uart/rtl/uart_rx.v
read_verilog third_party/alexforencich_uart/rtl/uart_tx.v


synth_ice40 -json synth/netlist.json -top top

write_verilog -noexpr -noattr -simple-lhs synth/netlist.v
