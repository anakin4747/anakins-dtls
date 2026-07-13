Feature: Nexus and Specifier Mapping Property Hover Documentation

  Background:
    Given the language server is running
    And a devicetree source file is open

  Scenario: Hover on a "gpio-map" property name in a specifier nexus node returns the "<specifier>-map" section from the devicetree specification
    When hovering over a "gpio-map" property name in a connector nexus node
    Then the hover returns the contents of the "<specifier>-map" section from the devicetree specification
    And the hover title includes "Specifier Mapping"
    And hovering over a "gpio-map" property name on a non-nexus device node returns nothing
    And hovering over a "gpio-map" property name in a node named nexus without nexus properties returns nothing

  Scenario: Hover on a "gpio-map-mask" property name in a specifier nexus node returns the "<specifier>-map-mask" section from the devicetree specification
    When hovering over a "gpio-map-mask" property name in a connector nexus node
    Then the hover returns the contents of the "<specifier>-map-mask" section from the devicetree specification
    And the hover title includes "Specifier Mapping"
    And hovering over a "gpio-map-mask" property name on a non-nexus device node returns nothing
    And hovering over a "gpio-map-mask" property name in a node named nexus without nexus properties returns nothing

  Scenario: Hover on a "gpio-map-pass-thru" property name in a specifier nexus node returns the "<specifier>-map-pass-thru" section from the devicetree specification
    When hovering over a "gpio-map-pass-thru" property name in a connector nexus node
    Then the hover returns the contents of the "<specifier>-map-pass-thru" section from the devicetree specification
    And the hover title includes "Specifier Mapping"
    And hovering over a "gpio-map-pass-thru" property name on a non-nexus device node returns nothing
    And hovering over a "gpio-map-pass-thru" property name in a node named nexus without nexus properties returns nothing

  Scenario: Hover on a "#gpio-cells" property name in a specifier nexus node returns the "#<specifier>-cells" section from the devicetree specification
    When hovering over a "#gpio-cells" property name in a connector nexus node
    Then the hover returns the contents of the "\#<specifier>-cells" section from the devicetree specification
    And the hover title includes "Specifier Mapping"
