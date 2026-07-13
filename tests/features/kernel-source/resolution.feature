Feature: Kernel source resolution

  Background:
    Given the language server is running

  Scenario: A devicetree source file nested several directories below an in-tree kernel source tree resolves to that source tree
    Given a devicetree source file nested 3 directories below a directory containing Documentation/devicetree/bindings/ is open
    And the resolved kernel source has a YAML binding for the node's compatible string
    When hovering over the compatible property value
    Then the hover title includes the binding file path relative to the kernel source root

  Scenario: A devicetree source file nested several directories below a .anakins-dtls file resolves to the configured kernel source
    Given a devicetree source file nested 3 directories below a directory containing a .anakins-dtls file with S=../kernel_source is open
    And the resolved kernel source has a YAML binding for the node's compatible string
    When hovering over the compatible property value
    Then the hover title includes the binding file path relative to the kernel source root

  Scenario: An absolute path in a .anakins-dtls file's S= value resolves correctly
    Given a devicetree source file below a .anakins-dtls file with an absolute S= value is open
    And the resolved kernel source has a YAML binding for the node's compatible string
    When hovering over the compatible property value
    Then the hover title includes the binding file path relative to the kernel source root

  Scenario: A double-quoted path in a .anakins-dtls file's S= value resolves correctly
    Given a devicetree source file below a .anakins-dtls file with a double-quoted S= value is open
    And the resolved kernel source has a YAML binding for the node's compatible string
    When hovering over the compatible property value
    Then the hover title includes the binding file path relative to the kernel source root

  Scenario: A closer in-tree kernel source tree takes precedence over a farther .anakins-dtls file
    Given a devicetree source file below both a nearby directory containing Documentation/devicetree/bindings/ and a farther .anakins-dtls file is open
    When hovering over the compatible property value
    Then the hover title includes the binding file path relative to the kernel source root
    And the resolved kernel source is the nearby in-tree kernel source tree

  Scenario: A closer .anakins-dtls file takes precedence over a farther in-tree kernel source tree
    Given a devicetree source file below both a nearby .anakins-dtls file and a farther directory containing Documentation/devicetree/bindings/ is open
    When hovering over the compatible property value
    Then the hover title includes the binding file path relative to the kernel source root
    And the resolved kernel source is the nearby configured out-of-tree kernel source

  Scenario: A .anakins-dtls file with no S= line is ignored
    Given a devicetree source file below a .anakins-dtls file with no S= line is open
    When hovering over the compatible property value
    Then the hover title includes "Standard Properties"
    And the hover title does not include "Documentation/devicetree/bindings"

  Scenario: A .anakins-dtls file with a blank S= value is ignored
    Given a devicetree source file below a .anakins-dtls file with a blank S= value is open
    When hovering over the compatible property value
    Then the hover title includes "Standard Properties"
    And the hover title does not include "Documentation/devicetree/bindings"
