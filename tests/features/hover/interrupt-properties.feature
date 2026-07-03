Feature: Interrupt Property Hover Documentation

  Background:
    Given the language server is running
    And a devicetree source file is open

  Scenario: Hover on an "interrupts" property name returns the "interrupts" section from the devicetree specification
    When hovering over an "interrupts" property name
    Then the hover returns the contents of the "interrupts" section from the devicetree specification

  Scenario: Hover on an "interrupt-parent" property name returns the "interrupt-parent" section from the devicetree specification
    When hovering over an "interrupt-parent" property name
    Then the hover returns the contents of the "interrupt-parent" section from the devicetree specification

  Scenario: Hover on an "interrupts-extended" property name returns the "interrupts-extended" section from the devicetree specification
    When hovering over an "interrupts-extended" property name
    Then the hover returns the contents of the "interrupts-extended" section from the devicetree specification

  Scenario: Hover on an "interrupt-controller" property name returns the "interrupt-controller" section from the devicetree specification
    When hovering over an "interrupt-controller" property name
    Then the hover returns the contents of the "interrupt-controller" section from the devicetree specification

  Scenario: Hover on a "#interrupt-cells" property name returns the "#interrupt-cells" section from the devicetree specification
    When hovering over a "#interrupt-cells" property name
    Then the hover returns the contents of the "\#interrupt-cells" section from the devicetree specification

  Scenario: Hover on an "interrupt-map" property name returns the "interrupt-map" section from the devicetree specification
    When hovering over an "interrupt-map" property name
    Then the hover returns the contents of the "interrupt-map" section from the devicetree specification
    And hovering over an "interrupt-map" property name on a non-nexus device node returns nothing

  Scenario: Hover on an "interrupt-map-mask" property name returns the "interrupt-map-mask" section from the devicetree specification
    When hovering over an "interrupt-map-mask" property name
    Then the hover returns the contents of the "interrupt-map-mask" section from the devicetree specification
    And hovering over an "interrupt-map-mask" property name on a non-nexus device node returns nothing
