
# Include UART-related modules
read_verilog rtl/uart_mod.sv
read_verilog -sv rtl/uart_alu.sv

read_verilog -sv rtl/packet_parser.sv
read_verilog -sv rtl/counter.sv
read_verilog -sv rtl/fifo_1r1w.sv
read_verilog -sv rtl/ram_1r1w_sync.sv

read_verilog synth/icestorm_icebreaker/icebreaker.v

read_verilog third_party/alexforencich_uart/rtl/uart_rx.v
read_verilog third_party/alexforencich_uart/rtl/uart_tx.v

# Synthesize the design for iCEBreaker
synth_ice40 -top icebreaker              # Specify uart_alu as the top-level module

# Output the synthesized design
write_json synth/netlist.json
write_verilog -noexpr -noattr -simple-lhs synth/netlist.v
