
############################################################################
# Timing Constrains
####################################################################################

set refclk [get_clocks -of_objects [get_pins {u_mmcm_0/mmcm_0_/inst/mmcm_adv_inst/CLKOUT0}]]

set_input_delay -clock $refclk 2.000 [get_ports -filter { NAME =~  "i_rst" && DIRECTION == "IN" }]
set_max_delay -from [get_ports i_rst] -to [get_pins u_rst_s2ff/sync_ff1_reg/C] 5.500
set_min_delay -from [get_ports i_rst] -to [get_pins u_rst_s2ff/sync_ff1_reg/C] 1.000

set_input_delay -clock $refclk 2.000 [get_ports -filter { NAME =~  "i_RsRx" && DIRECTION == "IN" }]
set_max_delay -from [get_ports i_RsRx] -to [get_pins u_uart_rx_s2ff/sync_ff1_reg/C] 5.500
set_min_delay -from [get_ports i_RsRx] -to [get_pins u_uart_rx_s2ff/sync_ff1_reg/C] 1.000

set_output_delay -clock $refclk 2.000 [get_ports -filter { NAME =~  "o_RsTx" && DIRECTION == "OUT" }]

#set_output_delay -clock $refclk 2 [get_ports -filter { NAME =~  "o_RsTx" && DIRECTION == "OUT" }]

