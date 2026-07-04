# anakins-dtls

A Device Tree Language Server.

## Non-Negotiable Rules

- Run tests with `make`; do not run `pytest` directly.
- Keep each commit focused on one workflow phase.
- Never implement a feature or parser fix before the required failing test commit exists.
- Do not mix tests and implementation.
- Review every workflow phase before committing it. Test code, fixtures, step
  definitions, tooling, application code, and docs are all codebase changes and
  must be reviewed for ownership, duplication, maintainability, and workflow
  boundaries.
- Validate every workflow commit only touches its allowed files with:
```sh
git diff-tree --no-commit-id --name-only -r HEAD
```
- If a workflow commit changes files outside its allowed paths, amend it and revalidate the touched files before continuing.
- Pause for user review only when the user explicitly asks.

## Mandatory Workflow Gate

Before making any edit, determine whether the user request matches a workflow.

If the request adds or changes user-visible behavior, the Feature Workflow must
be used. If the request fixes `tools/generate_docs.py` parsing or formatting of
Device Tree Specification content, the Documentation Parsing Bug Workflow must be
used.

When a workflow applies, declare the current workflow phase before editing files.
Do not skip, reorder, merge, or reinterpret workflow phases. The phrase
"allowed files" describes valid commit contents only; it does not override phase
order, first-edit requirements, or required failing-test-before-implementation
rules.

## Pre-Edit Workflow Check

Before every edit in a workflow, check:
- Workflow
- Phase
- Target file
- Why the file is allowed in this phase
- Whether every required prior gate is already satisfied
- For step-definition edits, whether the change only connects scenario wording to
  existing helpers and does not add Device Tree Specification parsing, RST table
  parsing, hover markdown formatting, or documentation-generation logic

If a required prior gate is not satisfied, self-correct by performing the missing
earlier workflow action first, then return to the intended edit after the gate is
satisfied.

## Pre-Commit Review Gate

Before every workflow commit, review the staged diff. This review is mandatory
for all phases, including tests, fixtures, step definitions, tools, application
code, and docs. Ask:
- Does every changed file belong to the current workflow phase?
- Does any changed file contain logic that belongs in a different layer?
- Did this change duplicate existing helpers, parser behavior, formatter
  behavior, fixtures, or application behavior?
- Are step definitions still thin glue over existing helpers?
- Are tests asserting behavior without reimplementing the behavior under test?
- Is this commit limited to one workflow phase and one concern?
- Are there unrelated changes staged?

The Review Refactor Commit is an additional end-to-end review, not the first
time workflow changes are reviewed.

## Workflow Violation Self-Correction

If an edit violates workflow order, immediately identify the violated rule and
repair the workflow state without requesting user direction.

For an uncommitted violation made solely by the assistant, revert or replace only
the assistant-made violating edit needed to restore workflow order. Preserve all
unrelated user changes and any unrelated worktree changes. After repair,
continue from the earliest required workflow phase.

## Workflow Selection

- Use the Feature Workflow when adding user-visible behavior.
- Use the optional Feature Workflow DTS Specification TDD step only when the feature requires changing hover documentation generated from `devicetree-specification/`.
- Use the Documentation Parsing Bug Workflow for bugs in `tools/generate_docs.py` parsing or formatting of Device Tree Specification content.
- The `devicetree-specification/` submodule is the official Device Tree Specification source. Use it as the reference for hover documentation content.

## Feature Workflow

When adding a user-visible feature, use this commit sequence unless the user
explicitly asks for a different workflow.

### 1. BDD Test Commit

Purpose:
Start with user-visible behavior. Change the relevant `.feature` file first.
Only change step definitions when required to make the scenario executable. Only
change fixtures when required to provide input data for the scenario. Never
change step definitions or fixtures without changing a `.feature` file in the
same commit.

Hard gate:
- The first edited file in this phase must be `tests/features/**/*.feature`.
- Do not edit step definitions, `tests/features/conftest.py`, or fixtures until
  after a `.feature` file has already been modified in the working tree.
- Before editing any non-`.feature` BDD file, verify the working diff already
  includes at least one `tests/features/**/*.feature` file.
- If the working diff does not already include a `.feature` file, self-correct by
  editing the relevant `.feature` file first, then return to the required
  step-definition or fixture edit.

Hover fixture guidance:
- Any target in a hover fixture whose purpose is to assert that no hover is
  returned must include an inline comment explaining why no hover is expected.
  This applies to invalid placements, node declarations outside their valid
  scope, and properties that are only valid in specific nodes.

Step-definition boundary:
- Keep BDD step definitions thin. They may locate hover targets, call the
  language server, compare actual hover text to expected text, and call existing
  test, application, or tool helpers.
- Do not add Device Tree Specification parsing, RST table parsing, hover
  markdown formatting, or documentation-generation logic to BDD step
  definitions.
- In this phase, step-definition changes may only adapt scenario wording to
  existing helpers or compose existing helpers.
- If a BDD assertion needs a new way to derive expected hover text from the
  Device Tree Specification, do not implement that logic in step definitions.
  Add the required DTS Specification generation test phase first, then implement
  the parsing or formatting behavior in `tools/`.

BDD phase review:
- Before committing BDD changes, review every changed `.feature`, fixture, and
  step-definition file.
- Confirm `.feature` files describe behavior, not implementation details.
- Confirm fixtures contain only input data and target markers needed by the
  scenarios.
- Confirm step definitions only locate targets, invoke the language server, and
  compare results using existing helpers.
- Confirm step definitions do not parse the Device Tree Specification, format
  hover markdown, or duplicate logic from `tools/`, `anakins_dtls/`, or test
  helpers.
- Check existing helpers before adding any new assertion helper.

Do not change:
- Application code
- Docs-generation implementation
- Unit tests

Verify:
Run `make` and verify the test fails because the feature is not implemented.

Commit message:
```sh
git commit -m "test(bdd): require <feature behavior>"
```

Allowed files:
```text
tests/features/**/*.feature
tests/features/conftest.py
tests/features/step_definitions/**/*.py
tests/fixtures/**
```

Validation:
The commit is valid only if every changed file is allowed and at least one
changed file is a `.feature` file. If the commit is not valid, amend it until it
is valid.

### 2. Optional DTS Specification TDD Test Commit

Purpose:
If the feature requires changing hover documentation generated from the Device
Tree Specification, write the smallest failing unit test for the generation
contract before implementation. Do not make this commit if no DTS Specification
generation change is needed.

Do not change:
- DTS Specification generation implementation
- BDD features
- Step definitions
- Fixtures
- Application code

Verify:
Run `make` and verify the DTS Specification generation test fails.

Commit message:
```sh
git commit -m "test(dtspec): require <feature> hover docs generation"
```

Allowed files:
```text
tests/test_generate_docs.py
tests/**/test_generate_docs.py
```

Validation:
The commit is valid only if every changed file is a DTS Specification generation
test file. If the commit is not valid, amend it until it is valid.

### 3. Feature Implementation Commit

Purpose:
Implement only the behavior required by the failing BDD commit and optional DTS
Specification TDD commit.

Do not change:
- Tests
- Fixtures
- Feature files
- Step definitions

Verify:
Run `make` and verify all tests pass.

Commit message:
```sh
git commit -m "feat: support <feature behavior>"
```

Allowed files:
```text
anakins_dtls/**
tools/**
```

Validation:
The commit is valid only if every changed file is application or tool code and no
changed file is under `tests/`. If the commit is not valid, amend it until it is
valid.

### 4. Review Refactor Commit

Purpose:
After the passing feature commit, review the complete workflow diff since the
first commit of the feature, including BDD tests, fixtures, step definitions,
unit tests, tools, application code, and docs. Ask the following questions to see
how the code can be made cleaner:
- Did your change create any dead code?
- Did your change invalidate some comments?
- Is your change in the style of the codebase?
- Can guard clauses be used to avoid indented code?
- Can this code be refactored into a function to improve readability?
- Is this commit atomic and only focused on one topic?
- Did anything unrelated get included in the commit by accident?
- Does this code reuse functionality already present in the codebase?
- Did the commit duplicate any functionality already present in the codebase?
- Is there a simpler way to implement this solution?
- Did you add any extra functionality that doesn't have a corresponding test?
- Did any test, fixture, or step-definition code duplicate parser, formatter,
  application, or tool behavior?
- Did any changed file take ownership of logic that belongs in another layer?
- Are BDD step definitions still thin after all workflow phases?
- Are expected values produced by shared helpers instead of reimplemented in
  tests?

Refactor only if it improves the code without changing behavior. Skip this
commit when no useful refactor is found.

Do not change:
- Feature files
- Fixtures
- Unit tests

Verify:
Run `make` and verify all tests pass.

Commit message:
```sh
git commit -m "refactor: clarify <feature area>"
```

Allowed files:
```text
anakins_dtls/**
tools/**
tests/features/conftest.py
tests/features/step_definitions/**/*.py
```

Forbidden files:
```text
tests/**/*.feature
tests/test_*.py
tests/fixtures/**
```

Validation:
The commit is valid only if every changed file is allowed and no changed file is
forbidden. If the commit is not valid, amend it until it is valid.

## Documentation Parsing Bug Workflow

Documentation parsing bugs in `tools/generate_docs.py` must use TDD. Capture the
bug with the smallest failing unit test before changing parser or formatter
implementation.

Documentation-generation ownership:
All logic that parses Device Tree Specification RST content or formats generated
hover documentation belongs in `tools/generate_docs.py` and must be covered by
DTS Specification generation tests. BDD tests may consume generated documentation
or formatter helpers, but must not reimplement parsing or formatting behavior in
step definitions.

### 1. Failing DTS Specification Test Commit

Purpose:
Write the smallest failing Device Tree Specification generation test that
reproduces the parsing bug. Prefer inline RST samples unless the bug depends on
real specification structure from `devicetree-specification/`.

Do not change:
- DTS Specification generation implementation
- Application code
- BDD features
- Step definitions
- Fixtures

Verify:
Run `make` and verify the test fails because of the parsing bug.

Commit message:
```sh
git commit -m "test(dtspec): reproduce <spec parsing bug>"
```

Allowed files:
```text
tests/test_generate_docs.py
tests/**/test_generate_docs.py
```

Validation:
The commit is valid only if every changed file is a DTS Specification generation
test file. If the commit is not valid, amend it until it is valid.

### 2. DTS Specification Parser Fix Commit

Purpose:
Implement only the behavior required by the failing Device Tree Specification
generation test.

Do not change:
- Tests
- Application code
- BDD features
- Step definitions
- Fixtures

Verify:
Run `make` and verify all tests pass.

Commit message:
```sh
git commit -m "fix(dtspec): handle <spec parsing case>"
```

Allowed files:
```text
tools/**
```

Validation:
The commit is valid only if every changed file is Device Tree Specification
generation implementation. If the commit is not valid, amend it until it is
valid.

### 3. Optional DTS Specification Parser Refactor Commit

Purpose:
After the passing fix commit, review the Device Tree Specification generation
code and refactor only if it improves clarity without changing behavior. Skip
this commit when no useful refactor is found.

Do not change:
- Tests
- Application code

Verify:
Run `make` and verify all tests pass.

Commit message:
```sh
git commit -m "refactor(dtspec): clarify <parser area>"
```

Allowed files:
```text
tools/**
```

Forbidden files:
```text
tests/**
anakins_dtls/**
```

Validation:
The commit is valid only if every changed file is allowed and no changed file is
forbidden. If the commit is not valid, amend it until it is valid.
