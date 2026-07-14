Feature: Go to implementation for a compatible property value

  Background:
    Given the language server is running

  Scenario Outline: Go to implementation for a compatible property value with a matching driver jumps to the driver source
    Given a devicetree source file is open <location>
    And the kernel source has a driver bound to the node's compatible string
    When going to the implementation of the compatible property value
    Then the implementation response points to the location of the compatible string in the driver source file

    Examples:
      | location                                                                                |
      | inside a Linux kernel source tree (a directory containing Documentation/devicetree/bindings/) |
      | outside any kernel source tree, below a .anakins-dtls file containing S=../kernel_source       |

  Scenario: Go to implementation for a compatible property value with no matching driver returns nothing
    Given a devicetree source file is open inside a Linux kernel source tree (a directory containing Documentation/devicetree/bindings/)
    And the kernel source has no driver bound to the node's compatible string
    When going to the implementation of the compatible property value
    Then the implementation response contains no location
