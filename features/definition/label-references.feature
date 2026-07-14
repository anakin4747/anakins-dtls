Feature: Go to definition for label references in included dtsi files

  Background:
    Given the language server is running

  Scenario: Go to definition for a label reference resolves to a label defined in the same file
    Given a devicetree source file that defines a label and references that label in the same file is open
    When going to the definition of that label reference
    Then the definition response points to the location of the label definition in the same file

  Scenario: Go to definition for a label reference resolves to the label definition in an included dtsi file
    Given a devicetree source file that includes a dtsi file defining a label is open
    When going to the definition of that label reference
    Then the definition response points to the location of the label definition in the included dtsi file

  Scenario: Go to definition for a label reference resolves to a label defined in the second of several included dtsi files
    Given a devicetree source file includes two dtsi files, and a label reference in the devicetree source file matches a label defined in the second included dtsi file
    When going to the definition of that label reference
    Then the definition response points to the location of the label definition in the second included dtsi file

  Scenario: Go to definition for a label reference with no matching label definition returns nothing
    Given a devicetree source file has a label reference with no matching label definition in any included dtsi file
    When going to the definition of that label reference
    Then the definition response contains no location

  Scenario Outline: Go to definition for a label reference resolves to a label defined via the kernel source
    Given a devicetree source file below a "<kernel source location>" kernel source references a label defined in a dtsi file included from the kernel source
    When going to the definition of that label reference
    Then the definition response points to the location of the label definition in that dtsi file

    Examples:
      | kernel source location |
      | in-tree                |
      | out-of-tree            |

  Scenario: Go to definition for a label reference with no matching label anywhere in the kernel source returns nothing
    Given a devicetree source file references a label with no matching definition anywhere in the resolved kernel source
    When going to the definition of that label reference
    Then the definition response contains no location
