onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /aximem_ss_tb/dut/u_axi_slave_adapter/clk
add wave -noupdate /aximem_ss_tb/dut/u_axi_slave_adapter/resetn
add wave -noupdate -expand -group Rchannel /aximem_ss_tb/dut/u_axi_slave_adapter/axi_arvalid
add wave -noupdate -expand -group Rchannel /aximem_ss_tb/dut/u_axi_slave_adapter/axi_arready
add wave -noupdate -expand -group Rchannel /aximem_ss_tb/dut/u_axi_slave_adapter/axi_araddr
add wave -noupdate -expand -group Rchannel -color White /aximem_ss_tb/dut/u_axi_slave_adapter/axi_rvalid
add wave -noupdate -expand -group Rchannel /aximem_ss_tb/dut/u_axi_slave_adapter/axi_rready
add wave -noupdate -expand -group Rchannel /aximem_ss_tb/dut/u_axi_slave_adapter/axi_rdata
add wave -noupdate -expand -group Rchannel -color Yellow /aximem_ss_tb/dut/u_axi_slave_adapter/ar_pending
add wave -noupdate -expand -group Rchannel -color {Medium Spring Green} /aximem_ss_tb/dut/u_axi_slave_adapter/do_read
add wave -noupdate /aximem_ss_tb/dut/u_axi_slave_adapter/araddr
add wave -noupdate -expand -group Wchannel /aximem_ss_tb/dut/u_axi_slave_adapter/axi_awvalid
add wave -noupdate -expand -group Wchannel /aximem_ss_tb/dut/u_axi_slave_adapter/axi_awready
add wave -noupdate -expand -group Wchannel /aximem_ss_tb/dut/u_axi_slave_adapter/axi_awaddr
add wave -noupdate -expand -group Wchannel /aximem_ss_tb/dut/u_axi_slave_adapter/axi_wvalid
add wave -noupdate -expand -group Wchannel /aximem_ss_tb/dut/u_axi_slave_adapter/axi_wready
add wave -noupdate -expand -group Wchannel /aximem_ss_tb/dut/u_axi_slave_adapter/axi_wdata
add wave -noupdate -expand -group Wchannel /aximem_ss_tb/dut/u_axi_slave_adapter/axi_wstrb
add wave -noupdate -expand -group Wchannel /aximem_ss_tb/dut/u_axi_slave_adapter/wdata
add wave -noupdate -expand -group Wchannel /aximem_ss_tb/dut/u_axi_slave_adapter/wstrb
add wave -noupdate -expand -group Wchannel /aximem_ss_tb/dut/u_axi_slave_adapter/valid
add wave -noupdate -expand -group Wchannel /aximem_ss_tb/dut/u_axi_slave_adapter/ready
add wave -noupdate -expand -group Wchannel -color Red /aximem_ss_tb/dut/u_axi_slave_adapter/addr
add wave -noupdate -expand -group Wchannel /aximem_ss_tb/dut/u_axi_slave_adapter/wdata_t
add wave -noupdate -expand -group Wchannel /aximem_ss_tb/dut/u_axi_slave_adapter/wstrb_t
add wave -noupdate -expand -group Wchannel -color {Cornflower Blue} /aximem_ss_tb/dut/u_axi_slave_adapter/aw_pending
add wave -noupdate -expand -group Wchannel -color {Medium Orchid} /aximem_ss_tb/dut/u_axi_slave_adapter/w_pending
add wave -noupdate -expand -group Wchannel -color White /aximem_ss_tb/dut/u_axi_slave_adapter/do_write
add wave -noupdate /aximem_ss_tb/dut/u_axi_slave_adapter/awaddr
add wave -noupdate /aximem_ss_tb/dut/u_sram/word_addr
add wave -noupdate {/aximem_ss_tb/dut/u_sram/mem[3]}
add wave -noupdate /aximem_ss_tb/dut/u_sram/mem
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {695000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 385
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {504175 ps} {826097 ps}
