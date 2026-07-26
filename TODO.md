list_node_properties():
- works for a node referenced across multiple dts and dtsi files
- will be used for completion and diagnostics (double properties, missing
  required properties)
- still does best effort if syntax is broken due to recent editing that the user
  is not yet finished with

identifying standard nodes:
- fall back to standard properties and Miscellaneous Properties if no other one
  is found
- a serial device for Serial Class Binding determined by fallback compatible
  string containing one of ns8250 or substring match of *-hdlc$
- `National Semiconductor 16450/16550 Compatible UART Requirements` identified
  by compatible fallback to ns16550 or ns16550a
- `Network` devices identified by properties: address-bits, local-mac-address,
  mac-address, max-frame-size, max-speed, phy-connection-type, phy-handle
- `Power ISA Open PIC Interrupt Controllers` gets decided by compatible = "open-pic"
- ``simple-bus`` Compatible by compatible = "simple-bus"
- top level (outside root node or any references) for completion of `/dts-v1/`
  (if not already present) and `/memreserve/` and `/ {` (if not already
  present) and `&<available labels>` (only ones which haven't been used
  already) and #includes or /include/s

diagnostic rules:

- All devicetrees shall have a root node
- in `node-name@unit-address`, `node-name` shall be 1 to 31 characters in
  length
- in `node-name@unit-address`, `node-name` shall consist of only `0-9` `a-z` `A-Z` `,`  `.`  `_`  `+`  `-`
- in `node-name@unit-address`, `unit-address` shall consist of only `0-9` `a-z` `A-Z` `,`  `.`  `_`  `+`  `-`
- The `node-name` shall start with a lower or uppercase character
- If the node has no `reg` property, the `@unit-address` must be omitted
- In the case of *node-name* without an *@unit-address* the *node-name* shall
  be unique from any property names at the same level in the tree.
- A unit-address must match the reg property (omitting 0x in the unit-address
  for hex values)
- property names shall be 1 to 31 characters in length
- property names shall consist of only  `0-9` `a-z` `A-Z` `,` `.` `_` `+` `?` `#` `-`
- a <u64> value shall be represented as two cells <0x11223344 0x55667788> so a
  single cell shall not be larger than 0xFFFFFFFF
- unmatched braces
- missing semi-colons
- uneven indenting as hints
- Nonstandard property names should specify a unique string prefix, such as a
  stock ticker symbol, identifying the name of the company or organization that
  defined the property. This could be a hint instead of an error. Use list from
  `Generic Names Recommendation` for determining Nonstandard property names.
- properties with values different from the type they should have
- `<prop-encoded-array>` doesn't match the property definition
- hints for deprecated nodes like `linux,phandle` or device_type properties
  outside of cpu and memory nodes
- errors on duplicate properties
- missing one /cpus node is an error
- more than one /cpus is an error
- missing /memory node
- ``/dts-v1/;`` shall be present to identify the file as a version 1 DTS
- The client program may access memory not covered by any memory reservations,
  so error if the client program tries to use reserved memory
- Unit address (``@<address>``) should be appended to the name if the node is a
  static allocation (for /reserved-memory child nodes)
- warnings if required root node properties do not exist
- hints if optional but recommended root node properties do not exist


Do rule checking on didOpen, didChange, and didSave

---

Hover:

                    # Devicetree Specification:

                    ## Property Name: model

                    ## Path: /model

                    ## Usage: Required

                    ## Value Type: `<string>`

                    ## Definition:

                    Specifies a string that uniquely identifies the model of the system board. The recommended format is "manufacturer,model-number".

                    ## Type Definition:


    Devicetree Bindings from Kernel Documentation: (Optional if found)

    /* ... */

    Devicetree Bindings from Specification: (Optional if found)

    /* ... */ from chapter 4

    Devicetree Specification:

    /* ... */

    Type Definition:

    /* ... */ from chapter 2

    Anakin's Opinion:

    /* ... */


---

cwd is sent via the initialize request or workspace/didChangeWorkspaceFolders

---

when you are in a dts you know that you are appending the nodes in dtsi but
when you are in dtsi the language server wont know which dts so it should have
to assume the perspective of the dtsi

---

damn need to handle state with didOpen and didChange and didClose

---

easiest I don't want to manage state when the filesystem already can
{
  "capabilities": {
    "textDocumentSync": 0 // 2 corresponds to Incremental, 1 to Full, 0 to None
  }
}

react on textDocument/didSave instead

---

a way to enable logging for getting a debug tracing for automated bug capturing

anakins-dtls --trace

---

and a way to save the json RPC messages from Neovim verbatim for known good
fixtures

anakins-dtls --save-rpc-to /path/to/save/to/

---

have the language server monitor its own memory usage to kill itself if it gets
too big for some reason

---

devicetree specification typos/mistakes:
- devicetree-specification/source/chapter3-devicenodes.rst:131:The *unit-name* component of the node name
    Shouldn't it say the *node-name* of the node shall be ``memory``.
- devicetree-specification/source/chapter3-devicenodes.rst:362:   ``memory-region-names`` O     ``<stringlist>>``         A list of names, one for each corresponding
    Double >> on stringlist
- devicetree-specification/source/chapter4-device-bindings.rst:142:.. table:: ``clock-frequecy`` Property
    frequency is spelled without an n
