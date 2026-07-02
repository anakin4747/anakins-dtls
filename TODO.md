
diagnostics:

- node-names can only be 1-31 characters long, diagnostics should warn if a
  node-name is longer than 31 characters
- node-names need to start with a lower or upper case letter, diagnostics
  should warn if a node name does not
- Diagnotics should warn if invalid characters are used in node-names,
  devicetree spec has a list of valid characters
- If the node has no reg property, the @unit-address must be omitted and the
  node-name alone differentiates the node from other nodes at the same level
  in the tree
- diagnostics for invalid characters in property names

figure out a way to have go to type definition take you to a tmp file that
contains the documentation for devicetree types
