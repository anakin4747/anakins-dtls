Feature: Standard Property Hover Documentation

  Background:
    Given the language server is running
    And a devicetree source file is open

  Scenario: Hover on "compatible" shows driver selection documentation
    Given a node with compatible = "fsl,mpc8641", "ns16550"
    When hovering over "compatible"
    Then the hover returns the contents of the "compatible" subsection from the devicetree specification

  Scenario: Hover on "model" shows manufacturer model number
    Given a node with model = "fsl,MPC8349EMITX"
    When hovering over "model"
    Then the hover returns the contents of the "model" subsection from the devicetree specification

  Scenario: Hover on "phandle" shows unique node identifier
    Given a node with phandle = <1>
    When hovering over "phandle"
    Then the hover returns the contents of the "phandle" subsection from the devicetree specification

  Scenario: Hover on "status" shows operational status
    Given a node with status = "disabled"
    When hovering over "status"
    Then the hover returns the contents of the "status" subsection from the devicetree specification

  Scenario: Hover on "#address-cells" shows child address encoding
    Given a node with address-cells = <1>
    When hovering over "#address-cells"
    Then the hover returns the contents of the "address-cells and size-cells" subsection from the devicetree specification

  Scenario: Hover on "#size-cells" shows child size encoding
    Given a node with size-cells = <1>
    When hovering over "#size-cells"
    Then the hover returns the contents of the "address-cells and size-cells" subsection from the devicetree specification

  Scenario: Hover on "reg" shows device address resources
    Given a node with reg = <0x3000 0x20 0xFE00 0x100>
    When hovering over "reg"
    Then the hover returns the contents of the "reg" subsection from the devicetree specification

  Scenario: Hover on "virtual-reg" shows virtual address mapping
    Given a node with virtual-reg
    When hovering over "virtual-reg"
    Then the hover returns the contents of the "virtual-reg" subsection from the devicetree specification

  Scenario: Hover on "ranges" shows address translation
    Given a bus node with ranges = <0x0 0xe0000000 0x00100000>
    When hovering over "ranges"
    Then the hover returns the contents of the "ranges" subsection from the devicetree specification

  Scenario: Hover on "dma-ranges" shows DMA address translation
    Given a bus node with dma-ranges
    When hovering over "dma-ranges"
    Then the hover returns the contents of the "dma-ranges" subsection from the devicetree specification

  Scenario: Hover on "dma-coherent" shows coherent DMA capability
    Given a node with dma-coherent
    When hovering over "dma-coherent"
    Then the hover returns the contents of the "dma-coherent" subsection from the devicetree specification

  Scenario: Hover on "dma-noncoherent" shows non-coherent DMA indication
    Given a node with dma-noncoherent
    When hovering over "dma-noncoherent"
    Then the hover returns the contents of the "dma-noncoherent" subsection from the devicetree specification

  Scenario: Hover on "name" shows node name identifier
    Given a node with name = "cpu"
    When hovering over "name"
    Then the hover returns the contents of the "name" subsection from the devicetree specification

  Scenario: Hover on "device_type" shows device type identifier
    Given a cpu node with device_type = "cpu"
    When hovering over "device_type"
    Then the hover returns the contents of the "device_type" subsection from the devicetree specification
