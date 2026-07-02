Feature: Interrupt Property Hover Documentation

  Background:
    Given the language server is running
    And a devicetree source file is open

  Scenario: Hover on "interrupts" shows device interrupt sources
    Given a node with interrupts = <0xA 8>
    When hovering over "interrupts"
    Then the hover returns the contents of the "interrupts" subsection from the devicetree specification

  Scenario: Hover on "interrupt-parent" shows explicit interrupt parent
    Given a node with interrupt-parent = <&pic>
    When hovering over "interrupt-parent"
    Then the hover returns the contents of the "interrupt-parent" subsection from the devicetree specification

  Scenario: Hover on "interrupts-extended" shows multi-controller interrupts
    Given a node with interrupts-extended = <&pic 0xA 8>, <&gic 0xda>
    When hovering over "interrupts-extended"
    Then the hover returns the contents of the "interrupts-extended" subsection from the devicetree specification

  Scenario: Hover on "interrupt-controller" marks interrupt controller node
    Given a node with interrupt-controller
    When hovering over "interrupt-controller"
    Then the hover returns the contents of the "interrupt-controller" subsection from the devicetree specification

  Scenario: Hover on "#interrupt-cells" shows interrupt specifier cell count
    Given an interrupt controller node with #interrupt-cells = <2>
    When hovering over "#interrupt-cells"
    Then the hover returns the contents of the "#interrupt-cells" subsection from the devicetree specification

  Scenario: Hover on "interrupt-map" shows interrupt routing table
    Given a nexus node with interrupt-map
    When hovering over "interrupt-map"
    Then the hover returns the contents of the "interrupt-map" subsection from the devicetree specification

  Scenario: Hover on "interrupt-map-mask" shows interrupt lookup mask
    Given a nexus node with interrupt-map-mask = <0xf800 0 0 7>
    When hovering over "interrupt-map-mask"
    Then the hover returns the contents of the "interrupt-map-mask" subsection from the devicetree specification
