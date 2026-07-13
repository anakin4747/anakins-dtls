Feature: Kernel source resolution

  Background:
    Given the language server is running

  Scenario: A devicetree source file nested several directories below an in-tree kernel source tree resolves to that source tree
    Given a devicetree source file nested 3 directories below a directory containing Documentation/devicetree/bindings/ is open
    And the resolved kernel source has a YAML binding for the node's compatible string
    When hovering over the compatible property value
    Then the hover title includes the binding file path relative to the kernel source root
