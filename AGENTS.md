# AGENTS.md

## Test-Driven Development (mandatory)

This project follows strict red-green TDD. For every change:

1. **Red** — Write or update a test that captures the desired behavior. Run
   `make` and confirm it fails for the expected reason (not a typo, syntax
   error, or unrelated failure).
2. **Green** — Write the minimal implementation code needed to make the
   failing test pass. Run `make` and confirm it now succeeds.
3. **Refactor** — Clean up implementation and test code while keeping `make`
   green. Re-run `make` after every refactor step.

Never write implementation code before a failing test exists for it. Never
mark a task done without having observed both the red and the green state
yourself.

## Test responsibilities

- Test behavior at the lowest level that owns it. Exhaustive inputs, boundary
  positions, permutations, and edge cases for a helper belong in that helper's
  direct tests.
- Higher-level tests should cover only the higher-level contract, such as
  orchestration, integration between helpers, output selection, and externally
  observable behavior. Use representative inputs instead of repeating every
  lower-level helper case.
- Before adding a higher-level assertion, check whether a lower-level test
  already proves the same behavior. Do not duplicate it unless the assertion
  also verifies a distinct higher-level responsibility.
- A spy test is appropriate when calling a shared helper is an intentional
  architectural requirement. This protects against bypassing tested helper
  logic, even when the resulting output would be the same.

## Running tests — `make` only

- The **only** command used to run tests is:

  ```
  make
  ```

- Do not invoke `busted`, `luacheck`, `stylua`, `cog`, or any other tool
  directly. `make` runs the full suite — code generation, tests, lint, and
  format checks — in the correct order. Running tests in isolation can hide
  lint/style/codegen failures that `make` would catch.
- If `make` fails, fix the root cause (test, implementation, lint, or
  formatting) and re-run `make` until it passes cleanly before moving on.
- Do not edit the `Makefile` to bypass or skip steps in order to make it pass.
- Never change lint or style configuration (e.g. `.luacheckrc`, `stylua.toml`,
  `.editorconfig`) to silence, relax, or sidestep a lint/style failure.
  Fix the actual code (or, in rare cases where a rule is genuinely wrong for
  the whole project, get explicit human sign-off first) instead of adjusting
  the config to make a failure go away.

## Git best practices

- Commit proactively, without waiting to be asked. As soon as a red-green
  (-refactor) cycle for one logical change reaches a passing `make`, commit
  it immediately before moving on to the next change. Do not batch up
  multiple unrelated red-green cycles into a single commit, and do not defer
  committing until the end of a session.
- Keep commits small and focused on a single logical change.
- Only commit when `make` passes.
- Write clear, imperative commit messages (e.g. "Add fixture for X",
  "Fix Y lint error"), matching existing history style (`git log --oneline`).
- Never commit unrelated files, generated cruft, or debug output.
- Inspect `git status` and `git diff` before staging; stage only intended
  files.
- Do not amend, force-push, or rewrite shared history unless explicitly
  asked.
- Do not create empty commits or skip commit hooks.
