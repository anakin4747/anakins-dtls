diagnostic rules:

- All devicetrees shall have a root node

- in `node-name@unit-address`, `node-name` shall be 1 to 31 characters in length
- in `node-name@unit-address`, `node-name` shall consist of only `0-9` `a-z` `A-Z` `,`  `.`  `_`  `+`  `-`
- in `node-name@unit-address`, `unit-address` shall consist of only `0-9` `a-z` `A-Z` `,`  `.`  `_`  `+`  `-`
- The `node-name` shall start with a lower or uppercase character
- If the node has no `reg` property, the `@unit-address` must be omitted
- In the case of *node-name* without an *@unit-address* the *node-name* shall be unique from any property names at the same level in the tree.
- A unit-address must match the reg property (omitting 0x in the unit-address for hex values)
- property names shall be 1 to 31 characters in length
- property names shall consist of only  `0-9` `a-z` `A-Z` `,` `.` `_` `+` `?` `#` `-`
- errors on duplicate properties

- Nonstandard property names should specify a unique string prefix, such as a
  stock ticker symbol, identifying the name of the company or organization that
  defined the property. This could be a hint instead of an error. Use list from
  `Generic Names Recommendation` for determining Nonstandard property names.
- properties with values different from the type they should have warnings
- `<prop-encoded-array>` doesn't match the property definition
- hints for deprecated nodes like `linux,phandle` or device_type properties outside of cpu and memory nodes
- missing one /cpus node is an error
- more than one /cpus is an error
- missing /memory node
- ``/dts-v1/;`` shall be present to identify the file as a version 1 DTS
- The client program may access memory not covered by any memory reservations, so error if the client program tries to use reserved memory
- Unit address (``@<address>``) should be appended to the name if the node is a static allocation (for /reserved-memory child nodes)
- warnings if required root node properties do not exist
- hints if optional but recommended root node properties do not exist
- diagnostics for incorrect prop encoded arrays

grep for the words shall, must, required, for warnings or errors diagnostics
grep for the words should, recommended for hints diagnostics

---

have the language server monitor its own memory usage to kill itself if it gets
too big for some reason

---

update all hovers to have the source of the info:

    Devicetree Specification: Standard Properties
    Devicetree Specification: Root Node Properties
    ...
---

Add more ## Anakin's Advice to provide laymans explanations for devicetree
nodes/properties as you come across them and understand them better

---

replace in_/on_ helpers with:

    get_node_location() -> in_an_aliases_node
    get_node_location() -> on_an_aliases_node

Or

gets the path of the node or property which can be used to determine what type of node the user is on

Need to think about all the ways of identifying nodes, for many devices it has
to do with th precence of specific properties or compatible strings

    get_node_or_prop_info() -> {
        is_property_name = false
        is_property_value = false
        path = "/path/to/node"
        properties = { dictionary of node properties }
    }

    get_node_or_prop_info() -> {
        is_property_name = true
        is_property_value = false
        path = "/path/to/node/property"
        properties = { dictionary of node properties }
    }

if it is not a property name or value then it is a node this will be used to
determine whether its a property or a node and whether its on the property name
or property value. Since the list of properties of that node is also always
gathered, this function can be used to determine node type for all those
serial, ethernet, etc devices as well as those which determine type based on
compatible string

Returns nothing on whitespace
Returns the node path on opening and closing node brackets

This way you don't have to iterate through all the helpers that all reparse the
same file over and over you just parse once and determine the type of node and
whether or not you are on or in the node

Or maybe actually implement AST parsing and determine from the tree instead?

---

Hover pulled from yaml files

This is a bad idea it would lead to so much lag in the hovers searching the yaml
everytime you want to hover.

Instead go to definition for properties should search the bindings

---

Hover over CPP macros

---

Completion

---

node references

---

in coming and out going calls

---

signature help for prop encoded arrays

---

devicetree specification typos/mistakes:
- devicetree-specification/source/chapter3-devicenodes.rst:131:The *unit-name* component of the node name
    Shouldn't it say the *node-name* of the node shall be ``memory``.
- devicetree-specification/source/chapter3-devicenodes.rst:362:   ``memory-region-names`` O     ``<stringlist>>``         A list of names, one for each corresponding
    Double >> on stringlist
- devicetree-specification/source/chapter4-device-bindings.rst:142:.. table:: ``clock-frequecy`` Property
    frequency is spelled without an n
- .. table:: ``/cpus/cpu*`` Node General Properties has array instead of
  prop_encoded_array

