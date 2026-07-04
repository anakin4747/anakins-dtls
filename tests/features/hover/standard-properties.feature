Feature: Standard Property Hover Documentation

  Background:
    Given the language server is running
    And a devicetree source file is open

  Scenario: Hover on a "compatible" property name returns the "compatible" section from the devicetree specification
    When hovering over a "compatible" property name
    Then the hover returns the contents of the "compatible" section from the devicetree specification
    And the hover title includes "Standard Properties"

  Scenario: Hover on a "model" property name returns the "model" section from the devicetree specification
    When hovering over a "model" property name
    Then the hover returns the contents of the "model" section from the devicetree specification
    And the hover title includes "Standard Properties"

  Scenario: Hover on a "phandle" property name returns the "phandle" section from the devicetree specification
    When hovering over a "phandle" property name
    Then the hover returns the contents of the "phandle" section from the devicetree specification
    And the hover title includes "Standard Properties"

  Scenario: Hover on a "linux,phandle" property name returns the "phandle" section from the devicetree specification
    When hovering over a "linux,phandle" property name
    Then the hover returns the contents of the "phandle" section from the devicetree specification
    And the hover title includes "Standard Properties"

  Scenario: Hover on a "status" property name returns the "status" section from the devicetree specification
    When hovering over a "status" property name
    Then the hover returns the contents of the "status" section from the devicetree specification
    And the hover title includes "Standard Properties"

  Scenario Outline: Hover on a "status" property value returns its row from the "Values for status property" table from the devicetree specification
    When the "status" property value is hovered for <value>
    Then the hover returns value and description for <value> from the "Values for status property" table from the devicetree specification
    And the hover title includes "Standard Properties"

    Examples:
      | value        |
      | "okay"      |
      | "disabled"  |
      | "reserved"  |
      | "fail"      |
      | "fail-sss"  |

  Scenario: Hover on a "#address-cells" property name returns the "\#address-cells and \#size-cells" section from the devicetree specification
    When hovering over a "#address-cells" property name
    Then the hover returns the contents of the "\#address-cells and \#size-cells" section from the devicetree specification
    And the hover title includes "Standard Properties"

  Scenario: Hover on a "#size-cells" property name returns the "\#address-cells and \#size-cells" section from the devicetree specification
    When hovering over a "#size-cells" property name
    Then the hover returns the contents of the "\#address-cells and \#size-cells" section from the devicetree specification
    And the hover title includes "Standard Properties"

  Scenario: Hover on a "reg" property name returns the "reg" section from the devicetree specification
    When hovering over a "reg" property name
    Then the hover returns the contents of the "reg" section from the devicetree specification
    And the hover title includes "Standard Properties"

  Scenario: Hover on a "virtual-reg" property name returns the "virtual-reg" section from the devicetree specification
    When hovering over a "virtual-reg" property name
    Then the hover returns the contents of the "virtual-reg" section from the devicetree specification
    And the hover title includes "Standard Properties"

  Scenario: Hover on a "ranges" property name returns the "ranges" section from the devicetree specification
    When hovering over a "ranges" property name
    Then the hover returns the contents of the "ranges" section from the devicetree specification
    And the hover title includes "Standard Properties"

  Scenario: Hover on a "dma-ranges" property name returns the "dma-ranges" section from the devicetree specification
    When hovering over a "dma-ranges" property name
    Then the hover returns the contents of the "dma-ranges" section from the devicetree specification
    And the hover title includes "Standard Properties"

  Scenario: Hover on a "dma-coherent" property name returns the "dma-coherent" section from the devicetree specification
    When hovering over a "dma-coherent" property name
    Then the hover returns the contents of the "dma-coherent" section from the devicetree specification
    And the hover title includes "Standard Properties"

  Scenario: Hover on a "dma-noncoherent" property name returns the "dma-noncoherent" section from the devicetree specification
    When hovering over a "dma-noncoherent" property name
    Then the hover returns the contents of the "dma-noncoherent" section from the devicetree specification
    And the hover title includes "Standard Properties"

  Scenario: Hover on a "name" property name returns the "name" section from the devicetree specification
    When hovering over a "name" property name
    Then the hover returns the contents of the "name (deprecated)" section from the devicetree specification
    And the hover title includes "Standard Properties"

  Scenario: Hover on a "device_type" property name returns the "device_type" section from the devicetree specification
    When hovering over a "device_type" property name
    Then the hover returns the contents of the "device_type (deprecated)" section from the devicetree specification
    And the hover title includes "Standard Properties"
