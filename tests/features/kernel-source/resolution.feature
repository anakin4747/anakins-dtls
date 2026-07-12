Feature: Kernel source resolution

  Background:
    Given the language server is running

  Scenario: A devicetree source file nested several directories below an in-tree kernel checkout resolves to that checkout
    Given a devicetree source file nested 3 directories below an in-tree kernel checkout is open
    And the resolved kernel source has a YAML binding for the node's compatible string
    When hovering over the compatible property value
    Then the hover title includes the binding file path relative to the kernel source root

  Scenario: A devicetree source file nested several directories below a configured out-of-tree kernel source resolves to that kernel source
    Given a devicetree source file nested 3 directories below a directory configured with an out-of-tree kernel source is open
    And the resolved kernel source has a YAML binding for the node's compatible string
    When hovering over the compatible property value
    Then the hover title includes the binding file path relative to the kernel source root

  Scenario: An absolute kernel source path in the configuration file resolves correctly
    Given a devicetree source file configured with an absolute out-of-tree kernel source path is open
    And the resolved kernel source has a YAML binding for the node's compatible string
    When hovering over the compatible property value
    Then the hover title includes the binding file path relative to the kernel source root

  Scenario: A closer in-tree kernel checkout takes precedence over a farther out-of-tree kernel source configuration
    Given a devicetree source file below both a nearby in-tree kernel checkout and a farther configured out-of-tree kernel source is open
    When hovering over the compatible property value
    Then the hover title includes the binding file path relative to the kernel source root
    And the resolved kernel source is the nearby in-tree checkout

  Scenario: A closer out-of-tree kernel source configuration takes precedence over a farther in-tree kernel checkout
    Given a devicetree source file below both a nearby configured out-of-tree kernel source and a farther in-tree kernel checkout is open
    When hovering over the compatible property value
    Then the hover title includes the binding file path relative to the kernel source root
    And the resolved kernel source is the nearby configured out-of-tree kernel source

  Scenario: A configuration file missing the kernel source value is ignored
    Given a devicetree source file below a kernel source configuration file with no kernel source value is open
    When hovering over the compatible property value
    Then the hover title includes "Standard Properties"
    And the hover title does not include "Documentation/devicetree/bindings"

  Scenario: A configuration file with a blank kernel source value is ignored
    Given a devicetree source file below a kernel source configuration file with a blank kernel source value is open
    When hovering over the compatible property value
    Then the hover title includes "Standard Properties"
    And the hover title does not include "Documentation/devicetree/bindings"
