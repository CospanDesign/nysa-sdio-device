nysa-sdio-device
================

SDIO device stack written in Verilog

Status: TLDR Version: Still designing and writing verilog cores

Designed to interface with SDIO Hosts. The associate Linux driver is at:
https://github.com/CospanDesign/nysa-sdio-linux-driver


Code Organization:

  rtl/
    sdio_stack.v (Top File that applications interface with)
    sdio_defines.v (Set defines for the stack are here)

    generic/ (Small modules that are used throughout the code are here)
      crc7.v (7-bit CRC Generator)
      crc16.v (16-bit CRC Generator)

    control/ (SDIO Card Controller)
      sdio_card_control.v

    cia/ (Common Information Area)
      sdio_cia.v  (This is where the SDIO card gets configured and contains
                    information for the host)
      sdio_cccr.v (Card Common Control Register)
      sdio_csi.v  (Card Information Structure)
      sdio_fbr.v  (Function Basic Registers)

    function/ (Function templates are here, use the function template to write
              your own interface)
      sdio_function_template.v

    phy/ (Physical level interface, these toggle the pins for both the command
          and data lines)
      sdio_phy.v (Main phy interface, all other phys are called through here)
      sdio_phy_sd_1_bit.v (1 data bit used with SD protocol)
      sdio_phy_sd_4_bit.v (4 data bits used with SD protocol)
      sdio_phy_spi.v      (SPI based interface on SD protocol)

  functions/
    nysa_host_interface/
      sdio_host_interface.v (SDIO Function that is a nysa host interface)
      sdio_host_interface_defines.v (Defines)


  sim/
    sdio_host/
      sdio_host.v (Used to exercise the sdio_device stack, this will
                  eventually become it's own repo)
