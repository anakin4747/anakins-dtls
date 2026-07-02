Feature: Nexus and Specifier Mapping Property Hover Documentation

  Background:
    Given the language server is running
    And a devicetree source file is open

  Scenario: Hover on "<specifier>-map" shows specifier domain mapping
    Given a nexus node with gpio-map
    When hovering over "gpio-map"
    Then the hover returns the contents of the "<specifier>-map" subsection from the devicetree specification

  Scenario: Hover on "<specifier>-map-mask" shows specifier lookup mask
    Given a nexus node with gpio-map-mask = <0xf 0x0>
    When hovering over "gpio-map-mask"
    Then the hover returns the contents of the "<specifier>-map-mask" subsection from the devicetree specification

  Scenario: Hover on "<specifier>-map-pass-thru" shows specifier pass-through mask
    Given a nexus node with gpio-map-pass-thru = <0x0 0x1>
    When hovering over "gpio-map-pass-thru"
    Then the hover returns the contents of the "<specifier>-map-pass-thru" subsection from the devicetree specification

  Scenario: Hover on "#<specifier>-cells" shows specifier cell count
    Given a nexus node with #gpio-cells = <2>
    When hovering over "#gpio-cells"
    Then the hover returns the contents of the "#<specifier>-cells" subsection from the devicetree specification
