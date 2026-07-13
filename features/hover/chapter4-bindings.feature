Feature: Chapter 4 Device Bindings Hover Documentation

  Background:
    Given the language server is running
    And a devicetree source file is open

  # --- Miscellaneous Properties ---

  Scenario: Hover on a "clock-frequency" property name on a miscellaneous device node returns the "``clock-frequency`` Property" section under the "Miscellaneous Properties" section from the devicetree specification
    When hovering over a "clock-frequency" property name on a miscellaneous device node
    Then the hover returns the contents of the "``clock-frequency`` Property" section under the "Miscellaneous Properties" section from the devicetree specification
    And the hover title includes "Miscellaneous Properties"
    And the hover does not return usage, value type, and definition for "clock-frequency" from the "``/cpus/cpu*`` Node General Properties" table from the devicetree specification
    And the hover does not return the contents of the "``clock-frequency`` Property" section under the "Serial Class Binding" section from the devicetree specification
    And the hover does not return usage, value type, and definition for "clock-frequency" from the "ns16550 UART Properties" table from the devicetree specification

  Scenario: Hover on a "reg-shift" property name on a miscellaneous device node returns the "``reg-shift`` Property" section under the "Miscellaneous Properties" section from the devicetree specification
    When hovering over a "reg-shift" property name on a miscellaneous device node
    Then the hover returns the contents of the "``reg-shift`` Property" section under the "Miscellaneous Properties" section from the devicetree specification
    And the hover title includes "Miscellaneous Properties"
    And the hover does not return usage, value type, and definition for "reg-shift" from the "ns16550 UART Properties" table from the devicetree specification

  Scenario: Hover on a "label" property name on a miscellaneous device node returns the "``label`` Property" section under the "Miscellaneous Properties" section from the devicetree specification
    When hovering over a "label" property name on a miscellaneous device node
    Then the hover returns the contents of the "``label`` Property" section under the "Miscellaneous Properties" section from the devicetree specification
    And the hover title includes "Miscellaneous Properties"

  # --- Serial devices ---

  Scenario: Hover on a "clock-frequency" property name on a serial node returns the "``clock-frequency`` Property" section under the "Serial Class Binding" section from the devicetree specification
    When hovering over a "clock-frequency" property name on a serial node
    Then the hover returns the contents of the "``clock-frequency`` Property" section under the "Serial Class Binding" section from the devicetree specification
    And the hover title includes "Serial Class Binding"
    And the hover does not return usage, value type, and definition for "clock-frequency" from the "``/cpus/cpu*`` Node General Properties" table from the devicetree specification
    And the hover does not return the contents of the "``clock-frequency`` Property" section under the "Miscellaneous Properties" section from the devicetree specification
    And the hover does not return usage, value type, and definition for "clock-frequency" from the "ns16550 UART Properties" table from the devicetree specification

  Scenario: Hover on a "current-speed" property name on a serial node returns the "``current-speed`` Property" section under the "Serial Class Binding" section from the devicetree specification
    When hovering over a "current-speed" property name on a serial node
    Then the hover returns the contents of the "``current-speed`` Property" section under the "Serial Class Binding" section from the devicetree specification
    And the hover title includes "Serial Class Binding"
    And the hover does not return usage, value type, and definition for "current-speed" from the "ns16550 UART Properties" table from the devicetree specification

  Scenario: Hover on a "clock-frequency" property name on a node named serial-device returns the miscellaneous clock-frequency documentation
    When hovering over a "clock-frequency" property name on a node named serial-device
    Then the hover returns the contents of the "``clock-frequency`` Property" section under the "Miscellaneous Properties" section from the devicetree specification
    And the hover title includes "Miscellaneous Properties"
    And the hover does not return the contents of the "``clock-frequency`` Property" section under the "Serial Class Binding" section from the devicetree specification
    And the hover does not return usage, value type, and definition for "clock-frequency" from the "ns16550 UART Properties" table from the devicetree specification

  # --- ns16550 UART ---

  Scenario: Hover on an "ns16550" compatible property value returns the "National Semiconductor 16450/16550 Compatible UART Requirements" section from the devicetree specification
    When hovering over an "ns16550" compatible property value
    Then the hover returns the contents of the "National Semiconductor 16450/16550 Compatible UART Requirements" section from the devicetree specification
    And the hover title includes "ns16550 UART"
    And hovering over a UART node declaration with an "ns16550" compatible property value returns nothing

  Scenario Outline: Hover on a "<property>" property name on an ns16550 UART node returns the "<property>" row from the "ns16550 UART Properties" table from the devicetree specification
    When hovering over a "<property>" property name on an ns16550 UART node
    Then the hover returns usage, value type, and definition for "<row>" from the "ns16550 UART Properties" table from the devicetree specification
    And the hover title includes "ns16550 UART"

    Examples:
      | property        | row             |
      | compatible      | compatible      |
      | current-speed   | current-speed   |
      | reg             | reg             |
      | interrupts      | interrupts      |
      | reg-shift       | reg-shift       |
      | virtual-reg     | virtual-reg     |

  Scenario: Hover on a "clock-frequency" property name on an ns16550 UART node returns the "clock-frequency" row from the "ns16550 UART Properties" table from the devicetree specification
    When hovering over a "clock-frequency" property name on an ns16550 UART node
    Then the hover returns usage, value type, and definition for "clock-frequency" from the "ns16550 UART Properties" table from the devicetree specification
    And the hover title includes "ns16550 UART"
    And the hover does not return usage, value type, and definition for "clock-frequency" from the "``/cpus/cpu*`` Node General Properties" table from the devicetree specification
    And the hover does not return the contents of the "``clock-frequency`` Property" section under the "Miscellaneous Properties" section from the devicetree specification
    And the hover does not return the contents of the "``clock-frequency`` Property" section under the "Serial Class Binding" section from the devicetree specification

  # --- Network devices ---

  Scenario: Hover on a network class device node declaration returns the "Network Class Binding" section from the devicetree specification
    When hovering over a network class device node declaration
    Then the hover returns the contents of the "Network Class Binding" section from the devicetree specification
    And the hover title includes "Network Class Binding"

  Scenario Outline: Hover on a "<property>" property name on a network device node returns that property section under the "Network Class Binding" section from the devicetree specification
    When hovering over a "<property>" property name on a network device node
    Then the hover returns the contents of the "``<property>`` Property" section under the "Network Class Binding" section from the devicetree specification
    And the hover title includes "Network Class Binding"

    Examples:
      | property          |
      | address-bits      |
      | local-mac-address |
      | mac-address       |
      | max-frame-size    |

  # --- Ethernet specific considerations ---

  Scenario: Hover on an Ethernet device node declaration returns the "Ethernet specific considerations" section from the devicetree specification
    When hovering over an Ethernet device node declaration
    Then the hover returns the contents of the "Ethernet specific considerations" section from the devicetree specification
    And the hover title includes "Ethernet specific considerations"

  Scenario Outline: Hover on a "<property>" property name on an Ethernet device node returns that property section under the "Ethernet specific considerations" section from the devicetree specification
    When hovering over a "<property>" property name on an Ethernet device node
    Then the hover returns the contents of the "``<property>`` Property" section under the "Ethernet specific considerations" section from the devicetree specification
    And the hover title includes "Ethernet specific considerations"

    Examples:
      | property            |
      | max-speed           |
      | phy-connection-type |
      | phy-handle          |

  # --- Power ISA Open PIC Interrupt Controllers ---

  Scenario: Hover on an "open-pic" compatible property value returns the "Power ISA Open PIC Interrupt Controllers" section from the devicetree specification
    When hovering over an "open-pic" compatible property value
    Then the hover returns the contents of the "Power ISA Open PIC Interrupt Controllers" section from the devicetree specification
    And the hover title includes "Open PIC interrupt controllers"
    And hovering over an interrupt controller node declaration with an "open-pic" compatible property value returns nothing

  Scenario Outline: Hover on a "<property>" property name on an Open PIC interrupt controller node returns the "<property>" row from the "Open-PIC properties" table from the devicetree specification
    When hovering over a "<property>" property name on an Open PIC interrupt controller node
    Then the hover returns usage, value type, and definition for "<property>" from the "Open-PIC properties" table from the devicetree specification
    And the hover title includes "Open PIC interrupt controllers"

    Examples:
      | property             |
      | compatible           |
      | reg                  |
      | #interrupt-cells     |
      | #address-cells       |
      | interrupt-controller |

  # --- simple-bus ---

  Scenario: Hover on a "simple-bus" compatible property value returns the "``simple-bus`` Compatible Value" section from the devicetree specification
    When hovering over a "simple-bus" compatible property value
    Then the hover returns the contents of the "``simple-bus`` Compatible Value" section from the devicetree specification
    And the hover title includes "simple-bus"
    And hovering over a node declaration with a "simple-bus" compatible property value returns nothing

  Scenario Outline: Hover on a "<property>" property name on a simple-bus node returns the "<property>" row from the "``simple-bus`` Compatible Node Properties" table from the devicetree specification
    When hovering over a "<property>" property name on a simple-bus node
    Then the hover returns usage, value type, and definition for "<property>" from the "``simple-bus`` Compatible Node Properties" table from the devicetree specification
    And the hover title includes "simple-bus"

    Examples:
      | property       |
      | compatible     |
      | ranges         |
      | nonposted-mmio |
