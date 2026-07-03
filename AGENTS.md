# anakins-dtls

A Device Tree Language Server.

## Feature Workflow

When adding a user-visible feature, use this commit sequence unless the user
explicitly asks for a different workflow. Keep each commit focused on its phase.

### 1. BDD Test Commit

Start with the user-visible behavior. Change the relevant `.feature` file first.
Only change step definitions when required to make the scenario executable. Only
change fixtures when required to provide input data for the scenario. Never
change step definitions or fixtures without changing a `.feature` file in the
same commit.

Do not change application code, docs-generation code, or unit tests in this
commit. Run `make` and verify the test fails because the feature is not
implemented.

Commit message template:
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

Validate the commit only changed the allowed files with:
```sh
git diff-tree --no-commit-id --name-only -r HEAD
```

The commit is valid only if every changed file is allowed and at least one
changed file is a `.feature` file. If the commit is not valid, amend it to
correct it until it is valid.

### 2. Optional Docs-Generation TDD Test Commit

If the feature requires changing docs-generation behavior, write the smallest
failing unit test for the docs-generation contract before implementation. Do not
make this commit if no docs-generation change is needed.

Do not change docs-generation implementation, BDD features, step definitions, or
fixtures in this commit. Run `make` and verify the docs-generation test fails.

Commit message template:
```sh
git commit -m "test(docs): require <feature> hover docs generation"
```

Allowed files:
```text
tests/test_generate_docs.py
tests/**/test_generate_docs.py
```

Validate the commit only changed the allowed files with:
```sh
git diff-tree --no-commit-id --name-only -r HEAD
```

The commit is valid only if every changed file is a docs-generation test file.
If the commit is not valid, amend it to correct it until it is valid.

### 3. Feature Implementation Commit

Implement only the behavior required by the failing BDD commit and optional
docs-generation TDD commit. Do not change tests, fixtures, feature files, or step
definitions in this commit.

Once the implementation of the feature is done run `make` to verify all tests
pass.

Commit message template:
```sh
git commit -m "feat: support <feature behavior>"
```

Allowed files:
```text
anakins_dtls/**
tools/**
```

Validate the commit only changed the allowed files with:
```sh
git diff-tree --no-commit-id --name-only -r HEAD
```

The commit is valid only if every changed file is application or tool code and no
changed file is under `tests/`. If the commit is not valid, amend it to correct
it until it is valid.

### 4. Review Refactor Commit

After the passing feature commit, code review the work. Ask the following
questions to see how the code can be made cleaner:
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

Refactor only if it improves the code without changing behavior. Save any
needed cleanup in this refactor commit.

Do not change feature files, fixtures, or unit tests in this commit. Run `make`
and verify all tests pass.

Commit message template:
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

Validate the commit with:
```sh
git diff-tree --no-commit-id --name-only -r HEAD
```

The commit is valid only if every changed file is allowed and no changed file is
forbidden. If the commit is not valid, amend it to correct it until it is valid.

## Bug Workflow

### Documentation Parsing Bugs

Documentation parsing bugs in `tools/generate_docs.py` must use TDD. Capture
the bug with the smallest failing unit test before changing parser or formatter
implementation.

#### 1. Failing DTS Specification Test Commit

Write the smallest failing Device Tree Specification generation test that
reproduces the parsing bug. Prefer inline RST samples unless the bug depends on
real specification structure from `devicetree-specification/`.

Do not change implementation, application code, BDD features, step definitions,
or fixtures in this commit. Run `make` and verify the test fails because of the
parsing bug.

Commit message template:
```sh
git commit -m "test(dtspec): reproduce <spec parsing bug>"
```

Allowed files:
```text
tests/test_generate_docs.py
tests/**/test_generate_docs.py
```

Validate the commit only changed the allowed files with:
```sh
git diff-tree --no-commit-id --name-only -r HEAD
```

The commit is valid only if every changed file is a Device Tree Specification
generation test file. If the commit is not valid, amend it to correct it until
it is valid.

#### 2. DTS Specification Parser Fix Commit

Implement only the behavior required by the failing Device Tree Specification
generation test. Do not change tests in this commit.

Run `make` and verify all tests pass.

Commit message template:
```sh
git commit -m "fix(dtspec): handle <spec parsing case>"
```

Allowed files:
```text
tools/**
```

Validate the commit only changed the allowed files with:
```sh
git diff-tree --no-commit-id --name-only -r HEAD
```

The commit is valid only if every changed file is Device Tree Specification
generation implementation. If the commit is not valid, amend it to correct it
until it is valid.

#### 3. Optional DTS Specification Parser Refactor Commit

After the passing fix commit, review the Device Tree Specification generation
code and refactor only if it improves clarity without changing behavior.

Run `make` and verify all tests pass.

Commit message template:
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

Validate the commit with:
```sh
git diff-tree --no-commit-id --name-only -r HEAD
```

The commit is valid only if every changed file is allowed and no changed file is
forbidden. If the commit is not valid, amend it to correct it until it is valid.
