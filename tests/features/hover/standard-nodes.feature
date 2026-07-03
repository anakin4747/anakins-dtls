Feature: Standard Top-Level Node Hover Documentation

  Background:
    Given the language server is running
    And a devicetree source file is open

  # Root node

  Scenario: Hover on a Root node returns the "Root node" section from the devicetree specification
    When hovering over a Root node declaration
    Then the hover returns the contents of the "Root node" section from the devicetree specification

  Scenario: Hover on a "serial-number" property name on the root node returns the definition of "serial-number" from the "Root node" section of the devicetree specification
    When hovering over a "serial-number" property name on the root node
    Then the hover returns the definition of "serial-number" from the "Root Node Properties" table from the devicetree specification

  # Scenario: Hover on "chassis-type" on the root node returns the definition of "chassis-type" from the "Root node" section of the devicetree specification
  #   Given a root node with chassis-type = "embedded"
  #   When hovering over "chassis-type" on the root node
  #   Then the hover returns the definition of "chassis-type" from the "Root node" section of the devicetree specification
  #
  # # /aliases node
  #
  # Scenario: Hover on "/aliases" returns the "/aliases node" section from the devicetree specification
  #   Given a devicetree with a "/aliases" node at the root
  #   When hovering over the node path "/aliases"
  #   Then the hover returns the contents of the "/aliases node" section from the devicetree specification
  #
  # # /memory node
  #
  # Scenario: Hover on "/memory" returns the "/memory node" section and subsections from the devicetree specification
  #   Given a devicetree with a "/memory" node at the root
  #   When hovering over the node path "/memory"
  #   Then the hover returns the contents of the "/memory node" section and subsections from the devicetree specification
  #
  # Scenario: Hover on "initial-mapped-area" on a memory node returns the definition of "initial-mapped-area" from the "/memory node" section of the devicetree specification
  #   Given a memory node with initial-mapped-area
  #   When hovering over "initial-mapped-area"
  #   Then the hover returns the definition of "initial-mapped-area" from the "/memory node" section of the devicetree specification
  #
  # Scenario: Hover on "hotpluggable" on a memory node returns the definition of "hotpluggable" from the "/memory node" section of the devicetree specification
  #   Given a memory node with hotpluggable
  #   When hovering over "hotpluggable"
  #   Then the hover returns the definition of "hotpluggable" from the "/memory node" section of the devicetree specification
  #
  # # /reserved-memory node
  #
  # Scenario: Hover on "/reserved-memory" returns the "/reserved-memory Node" section and subsections from the devicetree specification
  #   Given a devicetree with a "/reserved-memory" node at the root
  #   When hovering over the node path "/reserved-memory"
  #   Then the hover returns the contents of the "/reserved-memory Node" section and subsections from the devicetree specification
  #
  # Scenario: Hover on "size" on a reserved-memory child node returns the definition of "size" from the "/reserved-memory/ child nodes" section of the devicetree specification
  #   Given a reserved-memory child node with size
  #   When hovering over "size"
  #   Then the hover returns the definition of "size" from the "/reserved-memory/ child nodes" section of the devicetree specification
  #
  # Scenario: Hover on "alignment" on a reserved-memory child node returns the definition of "alignment" from the "/reserved-memory/ child nodes" section of the devicetree specification
  #   Given a reserved-memory child node with alignment
  #   When hovering over "alignment"
  #   Then the hover returns the definition of "alignment" from the "/reserved-memory/ child nodes" section of the devicetree specification
  #
  # Scenario: Hover on "alloc-ranges" on a reserved-memory child node returns the definition of "alloc-ranges" from the "/reserved-memory/ child nodes" section of the devicetree specification
  #   Given a reserved-memory child node with alloc-ranges
  #   When hovering over "alloc-ranges"
  #   Then the hover returns the definition of "alloc-ranges" from the "/reserved-memory/ child nodes" section of the devicetree specification
  #
  # Scenario: Hover on "no-map" on a reserved-memory child node returns the definition of "no-map" from the "/reserved-memory/ child nodes" section of the devicetree specification
  #   Given a reserved-memory child node with no-map
  #   When hovering over "no-map"
  #   Then the hover returns the definition of "no-map" from the "/reserved-memory/ child nodes" section of the devicetree specification
  #
  # Scenario: Hover on "reusable" on a reserved-memory child node returns the definition of "reusable" from the "/reserved-memory/ child nodes" section of the devicetree specification
  #   Given a reserved-memory child node with reusable
  #   When hovering over "reusable"
  #   Then the hover returns the definition of "reusable" from the "/reserved-memory/ child nodes" section of the devicetree specification
  #
  # Scenario: Hover on "memory-region" on a device node returns the definition of "memory-region" from the "/reserved-memory" section of the devicetree specification
  #   Given a device node with memory-region
  #   When hovering over "memory-region"
  #   Then the hover returns the definition of "memory-region" from the "/reserved-memory" section of the devicetree specification
  #
  # Scenario: Hover on "memory-region-names" on a device node returns the definition of "memory-region-names" from the "/reserved-memory" section of the devicetree specification
  #   Given a device node with memory-region-names
  #   When hovering over "memory-region-names"
  #   Then the hover returns the definition of "memory-region-names" from the "/reserved-memory" section of the devicetree specification
  #
  # # /chosen node
  #
  # Scenario: Hover on "/chosen" returns the "/chosen Node" section from the devicetree specification
  #   Given a devicetree with a "/chosen" node at the root
  #   When hovering over the node path "/chosen"
  #   Then the hover returns the contents of the "/chosen Node" section from the devicetree specification
  #
  # Scenario: Hover on "bootargs" on the chosen node returns the definition of "bootargs" from the "/chosen Node" section of the devicetree specification
  #   Given a chosen node with bootargs = "root=/dev/nfs"
  #   When hovering over "bootargs"
  #   Then the hover returns the definition of "bootargs" from the "/chosen Node" section of the devicetree specification
  #
  # Scenario: Hover on "bootsource" on the chosen node returns the definition of "bootsource" from the "/chosen Node" section of the devicetree specification
  #   Given a chosen node with bootsource
  #   When hovering over "bootsource"
  #   Then the hover returns the definition of "bootsource" from the "/chosen Node" section of the devicetree specification
  #
  # Scenario: Hover on "stdout-path" on the chosen node returns the definition of "stdout-path" from the "/chosen Node" section of the devicetree specification
  #   Given a chosen node with stdout-path
  #   When hovering over "stdout-path"
  #   Then the hover returns the definition of "stdout-path" from the "/chosen Node" section of the devicetree specification
  #
  # Scenario: Hover on "stdin-path" on the chosen node returns the definition of "stdin-path" from the "/chosen Node" section of the devicetree specification
  #   Given a chosen node with stdin-path
  #   When hovering over "stdin-path"
  #   Then the hover returns the definition of "stdin-path" from the "/chosen Node" section of the devicetree specification
  #
  # # /cpus node
  #
  # Scenario: Hover on "/cpus" returns the "/cpus Node Properties" section from the devicetree specification
  #   Given a devicetree with a "/cpus" node at the root
  #   When hovering over the node path "/cpus"
  #   Then the hover returns the contents of the "/cpus Node Properties" section from the devicetree specification
  #
  # # /cpus/cpu* nodes
  #
  # Scenario: Hover on a "/cpus/cpu*" node returns the "/cpus/cpu* Node Properties" section and subsections from the devicetree specification
  #   Given a devicetree with a "cpu" node under "/cpus"
  #   When hovering over the node path "/cpus/cpu@0"
  #   Then the hover returns the contents of the "/cpus/cpu* Node Properties" section and subsections from the devicetree specification
  #
  # Scenario: Hover on "clock-frequency" on a cpu node returns the definition of "clock-frequency" from the "/cpus/cpu* Node Properties" section of the devicetree specification
  #   Given a cpu node with clock-frequency
  #   When hovering over "clock-frequency"
  #   Then the hover returns the definition of "clock-frequency" from the "/cpus/cpu* Node Properties" section of the devicetree specification
  #
  # Scenario: Hover on "timebase-frequency" on a cpu node returns the definition of "timebase-frequency" from the "/cpus/cpu* Node Properties" section of the devicetree specification
  #   Given a cpu node with timebase-frequency
  #   When hovering over "timebase-frequency"
  #   Then the hover returns the definition of "timebase-frequency" from the "/cpus/cpu* Node Properties" section of the devicetree specification
  #
  # Scenario: Hover on "enable-method" on a cpu node returns the definition of "enable-method" from the "/cpus/cpu* Node Properties" section of the devicetree specification
  #   Given a disabled cpu node with enable-method = "spin-table"
  #   When hovering over "enable-method"
  #   Then the hover returns the definition of "enable-method" from the "/cpus/cpu* Node Properties" section of the devicetree specification
  #
  # Scenario: Hover on "cpu-release-addr" on a cpu node returns the definition of "cpu-release-addr" from the "/cpus/cpu* Node Properties" section of the devicetree specification
  #   Given a cpu node with cpu-release-addr
  #   When hovering over "cpu-release-addr"
  #   Then the hover returns the definition of "cpu-release-addr" from the "/cpus/cpu* Node Properties" section of the devicetree specification
  #
  # # Power ISA properties
  #
  # Scenario: Hover on "power-isa-version" on a cpu node returns the definition of "power-isa-version" from the "/cpus/cpu* Node Power ISA Properties" section of the devicetree specification
  #   Given a cpu node with power-isa-version = "2.06"
  #   When hovering over "power-isa-version"
  #   Then the hover returns the definition of "power-isa-version" from the "/cpus/cpu* Node Power ISA Properties" section of the devicetree specification
  #
  # Scenario: Hover on a "power-isa-*" category property on a cpu node returns the definition of "power-isa-*" from the "/cpus/cpu* Node Power ISA Properties" section of the devicetree specification
  #   Given a cpu node with power-isa-e-hv
  #   When hovering over "power-isa-e-hv"
  #   Then the hover returns the definition of "power-isa-*" from the "/cpus/cpu* Node Power ISA Properties" section of the devicetree specification
  #
  # Scenario: Hover on "cache-op-block-size" on a cpu node returns the definition of "cache-op-block-size" from the "/cpus/cpu* Node Power ISA Properties" section of the devicetree specification
  #   Given a cpu node with cache-op-block-size
  #   When hovering over "cache-op-block-size"
  #   Then the hover returns the definition of "cache-op-block-size" from the "/cpus/cpu* Node Power ISA Properties" section of the devicetree specification
  #
  # Scenario: Hover on "reservation-granule-size" on a cpu node returns the definition of "reservation-granule-size" from the "/cpus/cpu* Node Power ISA Properties" section of the devicetree specification
  #   Given a cpu node with reservation-granule-size
  #   When hovering over "reservation-granule-size"
  #   Then the hover returns the definition of "reservation-granule-size" from the "/cpus/cpu* Node Power ISA Properties" section of the devicetree specification
  #
  # Scenario: Hover on "mmu-type" on a cpu node returns the definition of "mmu-type" from the "/cpus/cpu* Node Power ISA Properties" section of the devicetree specification
  #   Given a cpu node with mmu-type = "powerpc-classic"
  #   When hovering over "mmu-type"
  #   Then the hover returns the definition of "mmu-type" from the "/cpus/cpu* Node Power ISA Properties" section of the devicetree specification
  #
  # # TLB properties
  #
  # Scenario: Hover on "tlb-split" on a cpu node returns the definition of "tlb-split" from the "/cpu/cpu* Node Power ISA TLB Properties" section of the devicetree specification
  #   Given a cpu node with tlb-split
  #   When hovering over "tlb-split"
  #   Then the hover returns the definition of "tlb-split" from the "/cpu/cpu* Node Power ISA TLB Properties" section of the devicetree specification
  #
  # Scenario: Hover on "tlb-size" on a cpu node returns the definition of "tlb-size" from the "/cpu/cpu* Node Power ISA TLB Properties" section of the devicetree specification
  #   Given a cpu node with tlb-size
  #   When hovering over "tlb-size"
  #   Then the hover returns the definition of "tlb-size" from the "/cpu/cpu* Node Power ISA TLB Properties" section of the devicetree specification
  #
  # Scenario: Hover on "tlb-sets" on a cpu node returns the definition of "tlb-sets" from the "/cpu/cpu* Node Power ISA TLB Properties" section of the devicetree specification
  #   Given a cpu node with tlb-sets
  #   When hovering over "tlb-sets"
  #   Then the hover returns the definition of "tlb-sets" from the "/cpu/cpu* Node Power ISA TLB Properties" section of the devicetree specification
  #
  # Scenario: Hover on "d-tlb-size" on a cpu node returns the definition of "d-tlb-size" from the "/cpu/cpu* Node Power ISA TLB Properties" section of the devicetree specification
  #   Given a cpu node with d-tlb-size
  #   When hovering over "d-tlb-size"
  #   Then the hover returns the definition of "d-tlb-size" from the "/cpu/cpu* Node Power ISA TLB Properties" section of the devicetree specification
  #
  # Scenario: Hover on "d-tlb-sets" on a cpu node returns the definition of "d-tlb-sets" from the "/cpu/cpu* Node Power ISA TLB Properties" section of the devicetree specification
  #   Given a cpu node with d-tlb-sets
  #   When hovering over "d-tlb-sets"
  #   Then the hover returns the definition of "d-tlb-sets" from the "/cpu/cpu* Node Power ISA TLB Properties" section of the devicetree specification
  #
  # Scenario: Hover on "i-tlb-size" on a cpu node returns the definition of "i-tlb-size" from the "/cpu/cpu* Node Power ISA TLB Properties" section of the devicetree specification
  #   Given a cpu node with i-tlb-size
  #   When hovering over "i-tlb-size"
  #   Then the hover returns the definition of "i-tlb-size" from the "/cpu/cpu* Node Power ISA TLB Properties" section of the devicetree specification
  #
  # Scenario: Hover on "i-tlb-sets" on a cpu node returns the definition of "i-tlb-sets" from the "/cpu/cpu* Node Power ISA TLB Properties" section of the devicetree specification
  #   Given a cpu node with i-tlb-sets
  #   When hovering over "i-tlb-sets"
  #   Then the hover returns the definition of "i-tlb-sets" from the "/cpu/cpu* Node Power ISA TLB Properties" section of the devicetree specification
  #
  # # Cache properties
  #
  # Scenario: Hover on "cache-unified" on a cpu node returns the definition of "cache-unified" from the "/cpu/cpu* Node Power ISA Cache Properties" section of the devicetree specification
  #   Given a cpu node with cache-unified
  #   When hovering over "cache-unified"
  #   Then the hover returns the definition of "cache-unified" from the "/cpu/cpu* Node Power ISA Cache Properties" section of the devicetree specification
  #
  # Scenario: Hover on "cache-size" on a cpu node returns the definition of "cache-size" from the "/cpu/cpu* Node Power ISA Cache Properties" section of the devicetree specification
  #   Given a cpu node with cache-size
  #   When hovering over "cache-size"
  #   Then the hover returns the definition of "cache-size" from the "/cpu/cpu* Node Power ISA Cache Properties" section of the devicetree specification
  #
  # Scenario: Hover on "cache-sets" on a cpu node returns the definition of "cache-sets" from the "/cpu/cpu* Node Power ISA Cache Properties" section of the devicetree specification
  #   Given a cpu node with cache-sets
  #   When hovering over "cache-sets"
  #   Then the hover returns the definition of "cache-sets" from the "/cpu/cpu* Node Power ISA Cache Properties" section of the devicetree specification
  #
  # Scenario: Hover on "cache-block-size" on a cpu node returns the definition of "cache-block-size" from the "/cpu/cpu* Node Power ISA Cache Properties" section of the devicetree specification
  #   Given a cpu node with cache-block-size
  #   When hovering over "cache-block-size"
  #   Then the hover returns the definition of "cache-block-size" from the "/cpu/cpu* Node Power ISA Cache Properties" section of the devicetree specification
  #
  # Scenario: Hover on "cache-line-size" on a cpu node returns the definition of "cache-line-size" from the "/cpu/cpu* Node Power ISA Cache Properties" section of the devicetree specification
  #   Given a cpu node with cache-line-size
  #   When hovering over "cache-line-size"
  #   Then the hover returns the definition of "cache-line-size" from the "/cpu/cpu* Node Power ISA Cache Properties" section of the devicetree specification
  #
  # Scenario: Hover on "i-cache-size" on a cpu node returns the definition of "i-cache-size" from the "/cpu/cpu* Node Power ISA Cache Properties" section of the devicetree specification
  #   Given a cpu node with i-cache-size
  #   When hovering over "i-cache-size"
  #   Then the hover returns the definition of "i-cache-size" from the "/cpu/cpu* Node Power ISA Cache Properties" section of the devicetree specification
  #
  # Scenario: Hover on "i-cache-sets" on a cpu node returns the definition of "i-cache-sets" from the "/cpu/cpu* Node Power ISA Cache Properties" section of the devicetree specification
  #   Given a cpu node with i-cache-sets
  #   When hovering over "i-cache-sets"
  #   Then the hover returns the definition of "i-cache-sets" from the "/cpu/cpu* Node Power ISA Cache Properties" section of the devicetree specification
  #
  # Scenario: Hover on "i-cache-block-size" on a cpu node returns the definition of "i-cache-block-size" from the "/cpu/cpu* Node Power ISA Cache Properties" section of the devicetree specification
  #   Given a cpu node with i-cache-block-size
  #   When hovering over "i-cache-block-size"
  #   Then the hover returns the definition of "i-cache-block-size" from the "/cpu/cpu* Node Power ISA Cache Properties" section of the devicetree specification
  #
  # Scenario: Hover on "i-cache-line-size" on a cpu node returns the definition of "i-cache-line-size" from the "/cpu/cpu* Node Power ISA Cache Properties" section of the devicetree specification
  #   Given a cpu node with i-cache-line-size
  #   When hovering over "i-cache-line-size"
  #   Then the hover returns the definition of "i-cache-line-size" from the "/cpu/cpu* Node Power ISA Cache Properties" section of the devicetree specification
  #
  # Scenario: Hover on "d-cache-size" on a cpu node returns the definition of "d-cache-size" from the "/cpu/cpu* Node Power ISA Cache Properties" section of the devicetree specification
  #   Given a cpu node with d-cache-size
  #   When hovering over "d-cache-size"
  #   Then the hover returns the definition of "d-cache-size" from the "/cpu/cpu* Node Power ISA Cache Properties" section of the devicetree specification
  #
  # Scenario: Hover on "d-cache-sets" on a cpu node returns the definition of "d-cache-sets" from the "/cpu/cpu* Node Power ISA Cache Properties" section of the devicetree specification
  #   Given a cpu node with d-cache-sets
  #   When hovering over "d-cache-sets"
  #   Then the hover returns the definition of "d-cache-sets" from the "/cpu/cpu* Node Power ISA Cache Properties" section of the devicetree specification
  #
  # Scenario: Hover on "d-cache-block-size" on a cpu node returns the definition of "d-cache-block-size" from the "/cpu/cpu* Node Power ISA Cache Properties" section of the devicetree specification
  #   Given a cpu node with d-cache-block-size
  #   When hovering over "d-cache-block-size"
  #   Then the hover returns the definition of "d-cache-block-size" from the "/cpu/cpu* Node Power ISA Cache Properties" section of the devicetree specification
  #
  # Scenario: Hover on "d-cache-line-size" on a cpu node returns the definition of "d-cache-line-size" from the "/cpu/cpu* Node Power ISA Cache Properties" section of the devicetree specification
  #   Given a cpu node with d-cache-line-size
  #   When hovering over "d-cache-line-size"
  #   Then the hover returns the definition of "d-cache-line-size" from the "/cpu/cpu* Node Power ISA Cache Properties" section of the devicetree specification
  #
  # Scenario: Hover on "next-level-cache" on a cpu node returns the definition of "next-level-cache" from the "/cpu/cpu* Node Power ISA Cache Properties" section of the devicetree specification
  #   Given a cpu node with next-level-cache
  #   When hovering over "next-level-cache"
  #   Then the hover returns the definition of "next-level-cache" from the "/cpu/cpu* Node Power ISA Cache Properties" section of the devicetree specification
  #
  # # Multi-level cache nodes
  #
  # Scenario: Hover on a cache node returns the "Multi-level and Shared Cache Nodes" section and subsections from the devicetree specification
  #   Given a devicetree with an "l2-cache" node under a cpu node
  #   When hovering over the node path "/cpus/cpu@0/l2-cache"
  #   Then the hover returns the contents of the "Multi-level and Shared Cache Nodes" section and subsections from the devicetree specification
  #
  # Scenario: Hover on "cache-level" on a cache node returns the definition of "cache-level" from the "Multi-level and Shared Cache Nodes" section of the devicetree specification
  #   Given a cache node with cache-level = <2>
  #   When hovering over "cache-level"
  #   Then the hover returns the definition of "cache-level" from the "Multi-level and Shared Cache Nodes" section of the devicetree specification
