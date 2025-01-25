
# Include UART-related modules

read_verilog -sv rtl/packet_parser.sv
read_verilog -sv rtl/counter.sv
read_verilog -sv rtl/fifo_1r1w.sv
read_verilog -sv rtl/ram_1r1w_sync.sv

read_verilog third_party/alexforencich_uart/rtl/uart_rx.v
read_verilog third_party/alexforencich_uart/rtl/uart_tx.v

read_verilog -sv rtl/CARRY4.sv
read_verilog -sv rtl/adder.sv
read_verilog -sv rtl/divider.sv


# read_verilog -sv third_party/basejump_stl/bsg_misc/bsg_dff_en.sv
# read_verilog -sv third_party/basejump_stl/bsg_misc/bsg_xnor.sv
# read_verilog -sv third_party/basejump_stl/bsg_misc/bsg_nor2.sv
# read_verilog -sv third_party/basejump_stl/bsg_misc/bsg_adder_cin.sv
# read_verilog -sv third_party/basejump_stl/bsg_misc/bsg_mux_one_hot.sv
# read_verilog -sv third_party/basejump_stl/bsg_misc/bsg_idiv_iterative_controller.sv

read_verilog -sv third_party/basejump_stl/bsg_misc/bsg_imul_iterative.sv
# read_verilog -sv third_party/basejump_stl/bsg_misc/bsg_idiv_iterative.sv

read_verilog rtl/uart_mod.sv
read_verilog -sv rtl/uart_alu.sv

read_verilog synth/icestorm_icebreaker/icebreaker.v

synth_ice40 -top icebreaker              # Specify uart_alu as the top-level module

write_json synth/netlist.json
write_verilog -noexpr -noattr -simple-lhs synth/netlist.v
