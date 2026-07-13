Feature: Kernel binding hover documentation

  Background:
    Given the language server is running

  Scenario Outline: Hovering over a compatible string with a matching binding shows the binding documentation
    Given a devicetree source file is open <location>
    And the kernel source has a <format> binding for the node's compatible string
    When hovering over the compatible property value
    Then the hover text includes the binding's title and description
    And the hover title includes the binding file path relative to the kernel source root

    Examples:
      | location                                                                                | format      |
      | inside a Linux kernel source tree (a directory containing Documentation/devicetree/bindings/) | YAML        |
      | outside any kernel source tree, below a .anakins-dtls file containing S=../kernel_source       | YAML        |
      | inside a Linux kernel source tree (a directory containing Documentation/devicetree/bindings/) | legacy text |
      | outside any kernel source tree, below a .anakins-dtls file containing S=../kernel_source       | legacy text |

  Scenario Outline: Hovering over a compatible string with no matching binding falls back to the standard properties documentation
    Given a devicetree source file is open <location>
    And the kernel source has no <format> binding for the node's compatible string
    When hovering over the compatible property value
    Then the hover title includes "Standard Properties"

    Examples:
      | location                                                                                | format      |
      | inside a Linux kernel source tree (a directory containing Documentation/devicetree/bindings/) | YAML        |
      | outside any kernel source tree, below a .anakins-dtls file containing S=../kernel_source       | YAML        |
      | inside a Linux kernel source tree (a directory containing Documentation/devicetree/bindings/) | legacy text |
      | outside any kernel source tree, below a .anakins-dtls file containing S=../kernel_source       | legacy text |
