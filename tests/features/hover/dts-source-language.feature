Feature: DTS source language hover documentation

  Background:
    Given the language server is running
    And a DTS source language file is open

  Scenario: Hover on the DTS version directive returns the "File layout" section from the devicetree specification
    When hovering over the DTS version directive
    Then the hover returns the contents of the "File layout" section from the devicetree specification
    And the hover title includes "DTS source language"

  Scenario: Hover on an include directive returns the "Compiler directives" section from the devicetree specification
    When hovering over an include directive
    Then the hover returns the contents of the "Compiler directives" section from the devicetree specification
    And the hover title includes "DTS source language"

  Scenario: Hover on a memory reservation directive returns the "File layout" section from the devicetree specification
    When hovering over a memory reservation directive
    Then the hover returns the contents of the "File layout" section from the devicetree specification
    And the hover title includes "DTS source language"

  Scenario: Hover on a delete-node directive returns the "Node and property definitions" section from the devicetree specification
    When hovering over a delete-node directive
    Then the hover returns the contents of the "Node and property definitions" section from the devicetree specification
    And the hover title includes "DTS source language"

  Scenario: Hover on a delete-property directive returns the "Node and property definitions" section from the devicetree specification
    When hovering over a delete-property directive
    Then the hover returns the contents of the "Node and property definitions" section from the devicetree specification
    And the hover title includes "DTS source language"

  Scenario: Hover on a label definition returns the "Labels" section from the devicetree specification
    When hovering over a label definition
    Then the hover returns the contents of the "Labels" section from the devicetree specification
    And the hover title includes "DTS source language"

  Scenario: Hover on a label reference returns the "Labels" section from the devicetree specification
    When hovering over a label reference
    Then the hover returns the contents of the "Labels" section from the devicetree specification
    And the hover title includes "DTS source language"

  Scenario: Hover on a full path reference returns the "Labels" section from the devicetree specification
    When hovering over a full path reference
    Then the hover returns the contents of the "Labels" section from the devicetree specification
    And the hover title includes "DTS source language"

  Scenario: Hover on a cell array returns the "Node and property definitions" section from the devicetree specification
    When hovering over a cell array
    Then the hover returns the contents of the "Node and property definitions" section from the devicetree specification
    And the hover title includes "DTS source language"

  Scenario: Hover on a bytestring returns the "Node and property definitions" section from the devicetree specification
    When hovering over a bytestring
    Then the hover returns the contents of the "Node and property definitions" section from the devicetree specification
    And the hover title includes "DTS source language"

  Scenario: Hover on a string property value returns the "Node and property definitions" section from the devicetree specification
    When hovering over a string property value
    Then the hover returns the contents of the "Node and property definitions" section from the devicetree specification
    And the hover title includes "DTS source language"

  Scenario Outline: Hover on a "<operator>" <operator_type> operator returns the "Node and property definitions" section from the devicetree specification
    When hovering over a "<operator>" <operator_type> operator
    Then the hover returns the contents of the "Node and property definitions" section from the devicetree specification
    And the hover title includes "DTS source language"

    Examples:
      | operator | operator_type |
      | +        | arithmetic    |
      | <<       | bitwise       |
      | &&       | logical       |
      | >=       | relational    |
      | ?        | ternary       |
      | :        | ternary       |
