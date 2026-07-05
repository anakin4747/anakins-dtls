Feature: Standard Top-Level Node Hover Documentation

  Background:
    Given the language server is running
    And a devicetree source file is open

  # Root node

  Scenario: Hover on a Root node returns the "Root node" section from the devicetree specification
    When hovering over a Root node declaration
    Then the hover returns the contents of the "Root node" section from the devicetree specification
    And the hover title includes "Root node"

  Scenario: Hover on a "model" property name on the root node returns the full "model" row from the "Root Node Properties" table from the devicetree specification
    When hovering over a "model" property name on the root node
    Then the hover returns usage, value type, and definition for "model" from the "Root Node Properties" table from the devicetree specification
    And the hover title includes "Root node"

  Scenario Outline: Hover on a "<property>" property name on the root node returns the "<property>" row from the "Root Node Properties" table from the devicetree specification
    When hovering over a "<property>" property name on the root node
    Then the hover returns usage, value type, and definition for "<property>" from the "Root Node Properties" table from the devicetree specification
    And the hover title includes "Root node"

    Examples:
      | property       |
      | #address-cells |
      | #size-cells    |
      | compatible     |

  Scenario: Hover on a "serial-number" property name on the root node returns the full "serial-number" row from the "Root Node Properties" table from the devicetree specification
    When hovering over a "serial-number" property name on the root node
    Then the hover returns usage, value type, and definition for "serial-number" from the "Root Node Properties" table from the devicetree specification
    And the hover title includes "Root node"
    And hovering over a "serial-number" property name outside the root node returns nothing

  Scenario: Hover on a "chassis-type" property name on the root node returns the full "chassis-type" row from the "Root Node Properties" table from the devicetree specification
    When hovering over a "chassis-type" property name on the root node
    Then the hover returns usage, value type, and definition for "chassis-type" from the "Root Node Properties" table from the devicetree specification
    And the hover title includes "Root node"
    And hovering over a "chassis-type" property name outside the root node returns nothing

  # /aliases node

  Scenario: Hover on an aliases node declaration on the root node returns the "/aliases node" section from the devicetree specification
    When hovering over an aliases node declaration on the root node
    Then the hover returns the contents of the "/aliases node" section from the devicetree specification
    And the hover title includes "Root node"
    And hovering over an aliases node declaration outside the root node returns nothing

  # /memory node

  Scenario: Hover on a memory node declaration on the root node returns the "/memory node" section from the devicetree specification
    When hovering over a memory node declaration on the root node
    Then the hover returns the contents of the "/memory node" section from the devicetree specification
    And the hover title includes "Root node"
    And hovering over a memory node declaration outside the root node returns nothing

  Scenario: Hover on an "initial-mapped-area" property name on a memory node returns the full "initial-mapped-area" row from the "``/memory`` Node Properties" table from the devicetree specification
    When hovering over an "initial-mapped-area" property name
    Then the hover returns usage, value type, and definition for "initial-mapped-area" from the "``/memory`` Node Properties" table from the devicetree specification
    And the hover title includes "/memory node"

  Scenario: Hover on a "hotpluggable" property name on a memory node returns the full "hotpluggable" row from the "``/memory`` Node Properties" table from the devicetree specification
    When hovering over a "hotpluggable" property name
    Then the hover returns usage, value type, and definition for "hotpluggable" from the "``/memory`` Node Properties" table from the devicetree specification
    And the hover title includes "/memory node"

  # /reserved-memory node

  Scenario: Hover on a reserved-memory node declaration on the root node returns the "``/reserved-memory`` Node" section from the devicetree specification
    When hovering over a reserved-memory node declaration on the root node
    Then the hover returns the contents of the "/reserved-memory Node" section from the devicetree specification
    And the hover title includes "Root node"

  Scenario Outline: Hover on a "<property>" property name in the reserved-memory node returns the "<property>" row from the "/reserved-memory Parent Node Properties" table from the devicetree specification
    When hovering over a "<property>" property name in the reserved-memory node
    Then the hover returns usage, value type, and definition for "<property>" from the "/reserved-memory Parent Node Properties" table from the devicetree specification
    And the hover title includes "/reserved-memory node"

    Examples:
      | property       |
      | #address-cells |
      | #size-cells    |
      | ranges         |

  Scenario Outline: Hover on a "<property>" property name on a reserved-memory child node returns the "<property>" row from the "``/reserved-memory/`` Child Node Properties" table from the devicetree specification
    When hovering over a "<property>" property name on a reserved-memory child node
    Then the hover returns usage, value type, and definition for "<property>" from the "``/reserved-memory/`` Child Node Properties" table from the devicetree specification
    And the hover title includes "/reserved-memory/ child nodes"

    Examples:
      | property   |
      | reg        |
      | compatible |

  Scenario: Hover on a "size" property name on a reserved-memory child node returns the full "size" row from the "``/reserved-memory/`` Child Node Properties" table from the devicetree specification
    When hovering over a "size" property name
    Then the hover returns usage, value type, and definition for "size" from the "``/reserved-memory/`` Child Node Properties" table from the devicetree specification
    And the hover title includes "/reserved-memory/ child nodes"

  Scenario: Hover on an "alignment" property name on a reserved-memory child node returns the full "alignment" row from the "``/reserved-memory/`` Child Node Properties" table from the devicetree specification
    When hovering over an "alignment" property name
    Then the hover returns usage, value type, and definition for "alignment" from the "``/reserved-memory/`` Child Node Properties" table from the devicetree specification
    And the hover title includes "/reserved-memory/ child nodes"

  Scenario: Hover on an "alloc-ranges" property name on a reserved-memory child node returns the full "alloc-ranges" row from the "``/reserved-memory/`` Child Node Properties" table from the devicetree specification
    When hovering over an "alloc-ranges" property name
    Then the hover returns usage, value type, and definition for "alloc-ranges" from the "``/reserved-memory/`` Child Node Properties" table from the devicetree specification
    And the hover title includes "/reserved-memory/ child nodes"

  Scenario: Hover on a "no-map" property name on a reserved-memory child node returns the full "no-map" row from the "``/reserved-memory/`` Child Node Properties" table from the devicetree specification
    When hovering over a "no-map" property name
    Then the hover returns usage, value type, and definition for "no-map" from the "``/reserved-memory/`` Child Node Properties" table from the devicetree specification
    And the hover title includes "/reserved-memory/ child nodes"

  Scenario: Hover on a "reusable" property name on a reserved-memory child node returns the full "reusable" row from the "``/reserved-memory/`` Child Node Properties" table from the devicetree specification
    When hovering over a "reusable" property name
    Then the hover returns usage, value type, and definition for "reusable" from the "``/reserved-memory/`` Child Node Properties" table from the devicetree specification
    And the hover title includes "/reserved-memory/ child nodes"

  Scenario: Hover on a "memory-region" property name on a device node returns the full "memory-region" row from the "Properties for referencing reserved-memory regions" table from the devicetree specification
    When hovering over a "memory-region" property name
    Then the hover returns usage, value type, and definition for "memory-region" from the "Properties for referencing reserved-memory regions" table from the devicetree specification
    And the hover title includes "reserved-memory references"
    And hovering over a "memory-region" property name on the root node returns nothing
    And hovering over a "memory-region" property name in the reserved-memory node returns nothing

  Scenario: Hover on a "memory-region-names" property name on a device node returns the full "memory-region-names" row from the "Properties for referencing reserved-memory regions" table from the devicetree specification
    When hovering over a "memory-region-names" property name
    Then the hover returns usage, value type, and definition for "memory-region-names" from the "Properties for referencing reserved-memory regions" table from the devicetree specification
    And the hover title includes "reserved-memory references"
    And hovering over a "memory-region-names" property name on the root node returns nothing
    And hovering over a "memory-region-names" property name in the reserved-memory node returns nothing

  # /chosen node

  Scenario: Hover on a chosen node declaration on the root node returns the "``/chosen`` Node" section from the devicetree specification
    When hovering over a chosen node declaration on the root node
    Then the hover returns the contents of the "/chosen Node" section from the devicetree specification
    And the hover title includes "Root node"

  Scenario: Hover on a "bootargs" property name on the chosen node returns the full "bootargs" row from the "``/chosen`` Node Properties" table from the devicetree specification
    When hovering over a "bootargs" property name
    Then the hover returns usage, value type, and definition for "bootargs" from the "``/chosen`` Node Properties" table from the devicetree specification
    And the hover title includes "/chosen node"

  Scenario: Hover on a "bootsource" property name on the chosen node returns the full "bootsource" row from the "``/chosen`` Node Properties" table from the devicetree specification
    When hovering over a "bootsource" property name
    Then the hover returns usage, value type, and definition for "bootsource" from the "``/chosen`` Node Properties" table from the devicetree specification
    And the hover title includes "/chosen node"

  Scenario: Hover on a "stdout-path" property name on the chosen node returns the full "stdout-path" row from the "``/chosen`` Node Properties" table from the devicetree specification
    When hovering over a "stdout-path" property name
    Then the hover returns usage, value type, and definition for "stdout-path" from the "``/chosen`` Node Properties" table from the devicetree specification
    And the hover title includes "/chosen node"

  Scenario: Hover on a "stdin-path" property name on the chosen node returns the full "stdin-path" row from the "``/chosen`` Node Properties" table from the devicetree specification
    When hovering over a "stdin-path" property name
    Then the hover returns usage, value type, and definition for "stdin-path" from the "``/chosen`` Node Properties" table from the devicetree specification
    And the hover title includes "/chosen node"

  # /cpus node

  Scenario: Hover on a cpus node declaration on the root node returns the "``/cpus`` Node Properties" section from the devicetree specification
    When hovering over a cpus node declaration on the root node
    Then the hover returns the contents of the "/cpus Node Properties" section from the devicetree specification
    And the hover title includes "Root node"

  Scenario Outline: Hover on a "<property>" property name on the cpus node returns the "<property>" row from the "``/cpus`` Node Properties" table from the devicetree specification
    When hovering over a "<property>" property name on the cpus node
    Then the hover returns usage, value type, and definition for "<property>" from the "``/cpus`` Node Properties" table from the devicetree specification
    And the hover title includes "/cpus node"

    Examples:
      | property       |
      | #address-cells |
      | #size-cells    |

  # /cpus/cpu* nodes

  Scenario: Hover on a cpu node declaration under the cpus node returns the "``/cpus/cpu*`` Node Properties" section from the devicetree specification
    When hovering over a cpu node declaration under the cpus node
    Then the hover returns the contents of the "/cpus/cpu* Node Properties" section from the devicetree specification
    And the hover title includes "/cpus/cpu* nodes"

  Scenario Outline: Hover on a "<property>" property name on a cpu node returns the full "<property>" row from the "``/cpus/cpu*`` Node General Properties" table from the devicetree specification
    When hovering over a "<property>" property name on a cpu node
    Then the hover returns usage, value type, and definition for "<property>" from the "``/cpus/cpu*`` Node General Properties" table from the devicetree specification
    And the hover title includes "/cpus/cpu* nodes"

    Examples:
      | property    |
      | device_type |
      | reg         |

  Scenario: Hover on a "clock-frequency" property name on a cpu node returns the full "clock-frequency" row from the "``/cpus/cpu*`` Node General Properties" table from the devicetree specification
    When hovering over a "clock-frequency" property name on a cpu node
    Then the hover returns usage, value type, and definition for "clock-frequency" from the "``/cpus/cpu*`` Node General Properties" table from the devicetree specification
    And the hover title includes "/cpus/cpu* nodes"
    And the hover does not return the contents of the "``clock-frequency`` Property" section under the "Miscellaneous Properties" section from the devicetree specification
    And the hover does not return the contents of the "``clock-frequency`` Property" section under the "Serial Class Binding" section from the devicetree specification
    And the hover does not return usage, value type, and definition for "clock-frequency" from the "ns16550 UART Properties" table from the devicetree specification

  Scenario: Hover on a "timebase-frequency" property name on a cpu node returns the full "timebase-frequency" row from the "``/cpus/cpu*`` Node General Properties" table from the devicetree specification
    When hovering over a "timebase-frequency" property name on a cpu node
    Then the hover returns usage, value type, and definition for "timebase-frequency" from the "``/cpus/cpu*`` Node General Properties" table from the devicetree specification
    And the hover title includes "/cpus/cpu* nodes"

  Scenario: Hover on an "enable-method" property name on a cpu node returns the full "enable-method" row from the "``/cpus/cpu*`` Node General Properties" table from the devicetree specification
    When hovering over an "enable-method" property name on a cpu node
    Then the hover returns usage, value type, and definition for "enable-method" from the "``/cpus/cpu*`` Node General Properties" table from the devicetree specification
    And the hover title includes "/cpus/cpu* nodes"

  Scenario: Hover on a "cpu-release-addr" property name on a cpu node returns the full "cpu-release-addr" row from the "``/cpus/cpu*`` Node General Properties" table from the devicetree specification
    When hovering over a "cpu-release-addr" property name on a cpu node
    Then the hover returns usage, value type, and definition for "cpu-release-addr" from the "``/cpus/cpu*`` Node General Properties" table from the devicetree specification
    And the hover title includes "/cpus/cpu* nodes"

  # Power ISA properties

  Scenario: Hover on a "power-isa-version" property name on a cpu node returns the full "power-isa-version" row from the "``/cpus/cpu*`` Node Power ISA Properties" table from the devicetree specification
    When hovering over a "power-isa-version" property name
    Then the hover returns usage, value type, and definition for "power-isa-version" from the "``/cpus/cpu*`` Node Power ISA Properties" table from the devicetree specification
    And the hover title includes "/cpus/cpu* Power ISA"

  Scenario: Hover on a "power-isa-e-hv" property name on a cpu node returns the full "power-isa-*" row from the "``/cpus/cpu*`` Node Power ISA Properties" table from the devicetree specification
    When hovering over a "power-isa-e-hv" property name
    Then the hover returns usage, value type, and definition for "power-isa-*" from the "``/cpus/cpu*`` Node Power ISA Properties" table from the devicetree specification
    And the hover title includes "/cpus/cpu* Power ISA"

  Scenario: Hover on a "cache-op-block-size" property name on a cpu node returns the full "cache-op-block-size" row from the "``/cpus/cpu*`` Node Power ISA Properties" table from the devicetree specification
    When hovering over a "cache-op-block-size" property name
    Then the hover returns usage, value type, and definition for "cache-op-block-size" from the "``/cpus/cpu*`` Node Power ISA Properties" table from the devicetree specification
    And the hover title includes "/cpus/cpu* Power ISA"

  Scenario: Hover on a "reservation-granule-size" property name on a cpu node returns the full "reservation-granule-size" row from the "``/cpus/cpu*`` Node Power ISA Properties" table from the devicetree specification
    When hovering over a "reservation-granule-size" property name
    Then the hover returns usage, value type, and definition for "reservation-granule-size" from the "``/cpus/cpu*`` Node Power ISA Properties" table from the devicetree specification
    And the hover title includes "/cpus/cpu* Power ISA"

  Scenario: Hover on a "mmu-type" property name on a cpu node returns the full "mmu-type" row from the "``/cpus/cpu*`` Node Power ISA Properties" table from the devicetree specification
    When hovering over a "mmu-type" property name
    Then the hover returns usage, value type, and definition for "mmu-type" from the "``/cpus/cpu*`` Node Power ISA Properties" table from the devicetree specification
    And the hover title includes "/cpus/cpu* Power ISA"

  # TLB properties

  Scenario: Hover on a "tlb-split" property name on a cpu node returns the full "tlb-split" row from the "``/cpu/cpu*`` Node Power ISA TLB Properties" table from the devicetree specification
    When hovering over a "tlb-split" property name
    Then the hover returns usage, value type, and definition for "tlb-split" from the "``/cpu/cpu*`` Node Power ISA TLB Properties" table from the devicetree specification
    And the hover title includes "/cpus/cpu* Power ISA TLB"

  Scenario: Hover on a "tlb-size" property name on a cpu node returns the full "tlb-size" row from the "``/cpu/cpu*`` Node Power ISA TLB Properties" table from the devicetree specification
    When hovering over a "tlb-size" property name
    Then the hover returns usage, value type, and definition for "tlb-size" from the "``/cpu/cpu*`` Node Power ISA TLB Properties" table from the devicetree specification
    And the hover title includes "/cpus/cpu* Power ISA TLB"

  Scenario: Hover on a "tlb-sets" property name on a cpu node returns the full "tlb-sets" row from the "``/cpu/cpu*`` Node Power ISA TLB Properties" table from the devicetree specification
    When hovering over a "tlb-sets" property name
    Then the hover returns usage, value type, and definition for "tlb-sets" from the "``/cpu/cpu*`` Node Power ISA TLB Properties" table from the devicetree specification
    And the hover title includes "/cpus/cpu* Power ISA TLB"

  Scenario: Hover on a "d-tlb-size" property name on a cpu node returns the full "d-tlb-size" row from the "``/cpu/cpu*`` Node Power ISA TLB Properties" table from the devicetree specification
    When hovering over a "d-tlb-size" property name
    Then the hover returns usage, value type, and definition for "d-tlb-size" from the "``/cpu/cpu*`` Node Power ISA TLB Properties" table from the devicetree specification
    And the hover title includes "/cpus/cpu* Power ISA TLB"

  Scenario: Hover on a "d-tlb-sets" property name on a cpu node returns the full "d-tlb-sets" row from the "``/cpu/cpu*`` Node Power ISA TLB Properties" table from the devicetree specification
    When hovering over a "d-tlb-sets" property name
    Then the hover returns usage, value type, and definition for "d-tlb-sets" from the "``/cpu/cpu*`` Node Power ISA TLB Properties" table from the devicetree specification
    And the hover title includes "/cpus/cpu* Power ISA TLB"

  Scenario: Hover on an "i-tlb-size" property name on a cpu node returns the full "i-tlb-size" row from the "``/cpu/cpu*`` Node Power ISA TLB Properties" table from the devicetree specification
    When hovering over an "i-tlb-size" property name
    Then the hover returns usage, value type, and definition for "i-tlb-size" from the "``/cpu/cpu*`` Node Power ISA TLB Properties" table from the devicetree specification
    And the hover title includes "/cpus/cpu* Power ISA TLB"

  Scenario: Hover on an "i-tlb-sets" property name on a cpu node returns the full "i-tlb-sets" row from the "``/cpu/cpu*`` Node Power ISA TLB Properties" table from the devicetree specification
    When hovering over an "i-tlb-sets" property name
    Then the hover returns usage, value type, and definition for "i-tlb-sets" from the "``/cpu/cpu*`` Node Power ISA TLB Properties" table from the devicetree specification
    And the hover title includes "/cpus/cpu* Power ISA TLB"

  # Cache properties

  Scenario: Hover on a "cache-unified" property name on a cpu node returns the full "cache-unified" row from the "``/cpu/cpu*`` Node Power ISA Cache Properties" table from the devicetree specification
    When hovering over a "cache-unified" property name
    Then the hover returns usage, value type, and definition for "cache-unified" from the "``/cpu/cpu*`` Node Power ISA Cache Properties" table from the devicetree specification
    And the hover title includes "/cpus/cpu* Power ISA cache"

  Scenario: Hover on a "cache-size" property name on a cpu node returns the full "cache-size" row from the "``/cpu/cpu*`` Node Power ISA Cache Properties" table from the devicetree specification
    When hovering over a "cache-size" property name
    Then the hover returns usage, value type, and definition for "cache-size" from the "``/cpu/cpu*`` Node Power ISA Cache Properties" table from the devicetree specification
    And the hover title includes "/cpus/cpu* Power ISA cache"

  Scenario: Hover on a "cache-sets" property name on a cpu node returns the full "cache-sets" row from the "``/cpu/cpu*`` Node Power ISA Cache Properties" table from the devicetree specification
    When hovering over a "cache-sets" property name
    Then the hover returns usage, value type, and definition for "cache-sets" from the "``/cpu/cpu*`` Node Power ISA Cache Properties" table from the devicetree specification
    And the hover title includes "/cpus/cpu* Power ISA cache"

  Scenario: Hover on a "cache-block-size" property name on a cpu node returns the full "cache-block-size" row from the "``/cpu/cpu*`` Node Power ISA Cache Properties" table from the devicetree specification
    When hovering over a "cache-block-size" property name
    Then the hover returns usage, value type, and definition for "cache-block-size" from the "``/cpu/cpu*`` Node Power ISA Cache Properties" table from the devicetree specification
    And the hover title includes "/cpus/cpu* Power ISA cache"

  Scenario: Hover on a "cache-line-size" property name on a cpu node returns the full "cache-line-size" row from the "``/cpu/cpu*`` Node Power ISA Cache Properties" table from the devicetree specification
    When hovering over a "cache-line-size" property name
    Then the hover returns usage, value type, and definition for "cache-line-size" from the "``/cpu/cpu*`` Node Power ISA Cache Properties" table from the devicetree specification
    And the hover title includes "/cpus/cpu* Power ISA cache"

  Scenario: Hover on an "i-cache-size" property name on a cpu node returns the full "i-cache-size" row from the "``/cpu/cpu*`` Node Power ISA Cache Properties" table from the devicetree specification
    When hovering over an "i-cache-size" property name
    Then the hover returns usage, value type, and definition for "i-cache-size" from the "``/cpu/cpu*`` Node Power ISA Cache Properties" table from the devicetree specification
    And the hover title includes "/cpus/cpu* Power ISA cache"

  Scenario: Hover on an "i-cache-sets" property name on a cpu node returns the full "i-cache-sets" row from the "``/cpu/cpu*`` Node Power ISA Cache Properties" table from the devicetree specification
    When hovering over an "i-cache-sets" property name
    Then the hover returns usage, value type, and definition for "i-cache-sets" from the "``/cpu/cpu*`` Node Power ISA Cache Properties" table from the devicetree specification
    And the hover title includes "/cpus/cpu* Power ISA cache"

  Scenario: Hover on an "i-cache-block-size" property name on a cpu node returns the full "i-cache-block-size" row from the "``/cpu/cpu*`` Node Power ISA Cache Properties" table from the devicetree specification
    When hovering over an "i-cache-block-size" property name
    Then the hover returns usage, value type, and definition for "i-cache-block-size" from the "``/cpu/cpu*`` Node Power ISA Cache Properties" table from the devicetree specification
    And the hover title includes "/cpus/cpu* Power ISA cache"

  Scenario: Hover on an "i-cache-line-size" property name on a cpu node returns the full "i-cache-line-size" row from the "``/cpu/cpu*`` Node Power ISA Cache Properties" table from the devicetree specification
    When hovering over an "i-cache-line-size" property name
    Then the hover returns usage, value type, and definition for "i-cache-line-size" from the "``/cpu/cpu*`` Node Power ISA Cache Properties" table from the devicetree specification
    And the hover title includes "/cpus/cpu* Power ISA cache"

  Scenario: Hover on a "d-cache-size" property name on a cpu node returns the full "d-cache-size" row from the "``/cpu/cpu*`` Node Power ISA Cache Properties" table from the devicetree specification
    When hovering over a "d-cache-size" property name
    Then the hover returns usage, value type, and definition for "d-cache-size" from the "``/cpu/cpu*`` Node Power ISA Cache Properties" table from the devicetree specification
    And the hover title includes "/cpus/cpu* Power ISA cache"

  Scenario: Hover on a "d-cache-sets" property name on a cpu node returns the full "d-cache-sets" row from the "``/cpu/cpu*`` Node Power ISA Cache Properties" table from the devicetree specification
    When hovering over a "d-cache-sets" property name
    Then the hover returns usage, value type, and definition for "d-cache-sets" from the "``/cpu/cpu*`` Node Power ISA Cache Properties" table from the devicetree specification
    And the hover title includes "/cpus/cpu* Power ISA cache"

  Scenario: Hover on a "d-cache-block-size" property name on a cpu node returns the full "d-cache-block-size" row from the "``/cpu/cpu*`` Node Power ISA Cache Properties" table from the devicetree specification
    When hovering over a "d-cache-block-size" property name
    Then the hover returns usage, value type, and definition for "d-cache-block-size" from the "``/cpu/cpu*`` Node Power ISA Cache Properties" table from the devicetree specification
    And the hover title includes "/cpus/cpu* Power ISA cache"

  Scenario: Hover on a "d-cache-line-size" property name on a cpu node returns the full "d-cache-line-size" row from the "``/cpu/cpu*`` Node Power ISA Cache Properties" table from the devicetree specification
    When hovering over a "d-cache-line-size" property name
    Then the hover returns usage, value type, and definition for "d-cache-line-size" from the "``/cpu/cpu*`` Node Power ISA Cache Properties" table from the devicetree specification
    And the hover title includes "/cpus/cpu* Power ISA cache"

  Scenario: Hover on a "next-level-cache" property name on a cpu node returns the full "next-level-cache" row from the "``/cpu/cpu*`` Node Power ISA Cache Properties" table from the devicetree specification
    When hovering over a "next-level-cache" property name
    Then the hover returns usage, value type, and definition for "next-level-cache" from the "``/cpu/cpu*`` Node Power ISA Cache Properties" table from the devicetree specification
    And the hover title includes "/cpus/cpu* Power ISA cache"

  # Multi-level cache nodes

  Scenario: Hover on a "cache" compatible property value returns the "Multi-level and Shared Cache Nodes (``/cpus/cpu*/l?-cache``)" section from the devicetree specification
    When hovering over a "cache" compatible property value
    Then the hover returns the contents of the "Multi-level and Shared Cache Nodes (``/cpus/cpu*/l?-cache``)" section from the devicetree specification
    And the hover title includes "/cpus/cpu*/l?-cache nodes"
    And hovering over a node declaration with a "cache" compatible property value returns nothing

  Scenario: Hover on a "compatible" property name in a cache node returns the full "compatible" row from the "``/cpu/cpu*/l?-cache`` Node Power ISA Multiple-level and Shared Cache Properties" table from the devicetree specification
    When hovering over a "compatible" property name in a cache node
    Then the hover returns usage, value type, and definition for "compatible" from the "``/cpu/cpu*/l?-cache`` Node Power ISA Multiple-level and Shared Cache Properties" table from the devicetree specification
    And the hover title includes "/cpus/cpu*/l?-cache nodes"

  Scenario: Hover on a "cache-level" property name on a cache node returns the full "cache-level" row from the "``/cpu/cpu*/l?-cache`` Node Power ISA Multiple-level and Shared Cache Properties" table from the devicetree specification
    When hovering over a "cache-level" property name
    Then the hover returns usage, value type, and definition for "cache-level" from the "``/cpu/cpu*/l?-cache`` Node Power ISA Multiple-level and Shared Cache Properties" table from the devicetree specification
    And the hover title includes "/cpus/cpu*/l?-cache nodes"
