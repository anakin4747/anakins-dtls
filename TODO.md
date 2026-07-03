
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
contains the documentation for devicetree types or return a hover if possible

---

for diagnostics pull out rules (sentances from the specification, often which
include the word shall) to be parsed out of feature files for implementing
diagnostics from the spec, or something like that

---

how to, when running make, first poll (only if 6 months have passed since the
last time it was supposed to poll previously) if there has been any updates to
the spec upstream and if there has automatically some ci that updates the spec,
runs the tests and if it all passes, it commits it as a chore: commit.

---

be able to specify sandbox rules by commands in anakins-agents

---

align devicetree spec submodule with the nix flake input
