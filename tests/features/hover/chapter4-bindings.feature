Feature: Chapter 4 Device Bindings Hover Documentation

  Background:
    Given the language server is running
    And a devicetree source file is open

  # --- Miscellaneous Properties ---

  Scenario: Hover on a "clock-frequency" property name on a miscellaneous device node returns the "``clock-frequency`` Property" section under the "Miscellaneous Properties" section from the devicetree specification
    When hovering over a "clock-frequency" property name on a miscellaneous device node
    Then the hover returns the contents of the "``clock-frequency`` Property" section under the "Miscellaneous Properties" section from the devicetree specification
    And the hover does not return usage, value type, and definition for "clock-frequency" from the "``/cpus/cpu*`` Node General Properties" table from the devicetree specification
    And the hover does not return the contents of the "``clock-frequency`` Property" section under the "Serial Class Binding" section from the devicetree specification
    And the hover does not return usage, value type, and definition for "clock-frequency" from the "ns16550 UART Properties" table from the devicetree specification

#   Scenario: Hover on "reg-shift" shows register shift property
#     Given a node with reg-shift = <2>
#     When hovering over a "reg-shift" property
#     Then the hover returns the contents of the "reg-shift Property" subsection of the "Miscellaneous Properties" section from the devicetree specification
#
#   Scenario: Hover on "label" shows device label property
#     Given a node with label = "ethernet0"
#     When hovering over a "label" property
#     Then the hover returns the contents of the "label Property" subsection from the devicetree specification
#
#   # --- Serial devices ---
#
#   Scenario: Hover on "clock-frequency" shows clock frequency property
#     Given a node with clock-frequency = <1000000>
#     When hovering over a "clock-frequency" property
#     Then the hover returns the contents of the "clock-frequency Property" subsection of the "Miscellaneous Properties" section from the devicetree specification
#
#   Scenario: Hover on "current-speed" on a serial device
#     Given a serial device node with current-speed = <115200>
#     When hovering over a "current-speed" property
#     Then the hover returns the contents of the "current-speed Property" subsection from the devicetree specification
#
#   # --- ns16550 UART ---
#
#   Scenario: Hover on an ns16550 UART node shows UART binding documentation
#     Given a node with compatible = "ns16550"
#     When hovering over the node declaration
#     Then the hover returns the contents of the "National Semiconductor 16450/16550 Compatible UART Requirements" subsection from the devicetree specification
#
#   Scenario: Hover on "compatible" on an ns16550 UART node
#     Given a node with compatible = "ns16550"
#     When hovering over a "compatible" property
#     Then the hover returns the definition of "compatible" from the "National Semiconductor 16450/16550 Compatible UART Requirements" subsection of the devicetree specification
#
#   Scenario: Hover on "clock-frequency" on an ns16550 UART node
#     Given a node with compatible = "ns16550", clock-frequency = <100000000>
#     When hovering over a "clock-frequency" property
#     Then the hover returns the definition of "clock-frequency" from the "National Semiconductor 16450/16550 Compatible UART Requirements" subsection of the devicetree specification
#
#   Scenario: Hover on "current-speed" on an ns16550 UART node
#     Given a node with compatible = "ns16550", current-speed = <115200>
#     When hovering over a "current-speed" property
#     Then the hover returns the definition of "current-speed" from the "National Semiconductor 16450/16550 Compatible UART Requirements" subsection of the devicetree specification
#
#   Scenario: Hover on "reg-shift" on an ns16550 UART node
#     Given a node with compatible = "ns16550", reg-shift = <2>
#     When hovering over a "reg-shift" property
#     Then the hover returns the definition of "reg-shift" from the "National Semiconductor 16450/16550 Compatible UART Requirements" subsection of the devicetree specification
#
#   Scenario: Hover on "virtual-reg" on an ns16550 UART node
#     Given a node with compatible = "ns16550", virtual-reg
#     When hovering over a "virtual-reg" property
#     Then the hover returns the definition of "virtual-reg" from the "National Semiconductor 16450/16550 Compatible UART Requirements" subsection of the devicetree specification
#
#   # --- Network devices ---
#
#   Scenario: Hover on a network class device node
#     Given a network device node
#     When hovering over the node declaration
#     Then the hover returns the contents of the "Network Class Binding" subsection from the devicetree specification
#
#   Scenario: Hover on "address-bits" on a network device
#     Given a network device node with address-bits = <48>
#     When hovering over a "address-bits" property
#     Then the hover returns the contents of the "address-bits Property" subsection from the devicetree specification
#
#   Scenario: Hover on "local-mac-address" on a network device
#     Given a network device node with local-mac-address
#     When hovering over a "local-mac-address" property
#     Then the hover returns the contents of the "local-mac-address Property" subsection from the devicetree specification
#
#   Scenario: Hover on "mac-address" on a network device
#     Given a network device node with mac-address
#     When hovering over a "mac-address" property
#     Then the hover returns the contents of the "mac-address Property" subsection from the devicetree specification
#
#   Scenario: Hover on "max-frame-size" on a network device
#     Given a network device node with max-frame-size = <1518>
#     When hovering over a "max-frame-size" property
#     Then the hover returns the contents of the "max-frame-size Property" subsection from the devicetree specification
#
#   # --- Ethernet specific considerations ---
#
#   Scenario: Hover on an Ethernet device node
#     Given an Ethernet device node
#     When hovering over the node declaration
#     Then the hover returns the contents of the "Ethernet specific considerations" subsection from the devicetree specification
#
#   Scenario: Hover on "max-speed" on an Ethernet device
#     Given an Ethernet device node with max-speed = <1000>
#     When hovering over a "max-speed" property
#     Then the hover returns the contents of the "max-speed Property" subsection from the devicetree specification
#
#   Scenario: Hover on "phy-connection-type" on an Ethernet device
#     Given an Ethernet device node with phy-connection-type = "rgmii"
#     When hovering over a "phy-connection-type" property
#     Then the hover returns the contents of the "phy-connection-type Property" subsection from the devicetree specification
#
#   Scenario: Hover on "phy-handle" on an Ethernet device
#     Given an Ethernet device node with phy-handle
#     When hovering over a "phy-handle" property
#     Then the hover returns the contents of the "phy-handle Property" subsection from the devicetree specification
#
#   # --- Power ISA Open PIC Interrupt Controllers ---
#
#   Scenario: Hover on an Open PIC interrupt controller node
#     Given a node with compatible = "open-pic"
#     When hovering over the node declaration
#     Then the hover returns the contents of the "Power ISA Open PIC Interrupt Controllers" section from the devicetree specification
#
#   Scenario: Hover on "compatible" on an Open PIC node
#     Given a node with compatible = "open-pic"
#     When hovering over a "compatible" property
#     Then the hover returns the definition of "compatible" from the "Power ISA Open PIC Interrupt Controllers" section of the devicetree specification
#
#   Scenario: Hover on "#interrupt-cells" on an Open PIC node
#     Given an interrupt controller node with #interrupt-cells = <2>
#     When hovering over a "#interrupt-cells" property
#     Then the hover returns the definition of "#interrupt-cells" from the "Power ISA Open PIC Interrupt Controllers" section of the devicetree specification
#
#   Scenario: Hover on "#address-cells" on an Open PIC node
#     Given an interrupt controller node with #address-cells = <0>
#     When hovering over a "#address-cells" property
#     Then the hover returns the definition of "#address-cells" from the "Power ISA Open PIC Interrupt Controllers" section of the devicetree specification
#
#   Scenario: Hover on "interrupt-controller" on an Open PIC node
#     Given an interrupt controller node with interrupt-controller
#     When hovering over a "interrupt-controller" property
#     Then the hover returns the definition of "interrupt-controller" from the "Power ISA Open PIC Interrupt Controllers" section of the devicetree specification
#
#   # --- simple-bus ---
#
#   Scenario: Hover on a simple-bus node
#     Given a node with compatible = "simple-bus"
#     When hovering over the node declaration
#     Then the hover returns the contents of the "simple-bus Compatible Value" section from the devicetree specification
#
#   Scenario: Hover on "ranges" on a simple-bus node
#     Given a simple-bus node with ranges
#     When hovering over a "ranges" property
#     Then the hover returns the definition of "ranges" from the "simple-bus Compatible Value" section of the devicetree specification
#
#   Scenario: Hover on "nonposted-mmio" on a simple-bus node
#     Given a simple-bus node with nonposted-mmio
#     When hovering over a "nonposted-mmio" property
#     Then the hover returns the definition of "nonposted-mmio" from the "simple-bus Compatible Value" section of the devicetree specification
