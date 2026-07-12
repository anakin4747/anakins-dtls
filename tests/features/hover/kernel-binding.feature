Feature: Kernel binding hover documentation

  Background:
    Given the language server is running

  Scenario Outline: Hovering over a compatible string with a matching binding shows the binding documentation
    Given an <context> devicetree source file is open
    And the <context> kernel source code has a <format> binding for the node's compatible string
    When hovering over the compatible property value
    Then the hover text includes the binding's title and description
    And the hover title includes the binding file path relative to the kernel source root

    Examples:
      | context     | format      |
      | in-tree     | YAML        |
      | out-of-tree | YAML        |
      | in-tree     | legacy text |
      | out-of-tree | legacy text |

  Scenario Outline: Hovering over a compatible string with no matching binding falls back to the standard properties documentation
    Given an <context> devicetree source file is open
    And the <context> kernel source code has no <format> binding for the node's compatible string
    When hovering over the compatible property value
    Then the hover title includes "Standard Properties"

    Examples:
      | context     | format      |
      | in-tree     | YAML        |
      | out-of-tree | YAML        |
      | in-tree     | legacy text |
      | out-of-tree | legacy text |

