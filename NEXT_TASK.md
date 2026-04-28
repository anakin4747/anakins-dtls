# Next Task: textDocument/publishDiagnostics

## Status: QUEUED (implement after refactor commit is pushed)

## Summary
Implement `textDocument/publishDiagnostics` push notifications in `anakins-dtls`.
Send diagnostics on `didOpen` and `didChange`.

## Diagnostics to implement

### 1. Missing semicolons (severity=1, error)
Lines with `=` that don't end with `;` (ignoring trailing whitespace/comments),
or `}` without `;` where one is expected.

### 2. Unclosed braces (severity=1, error)
Track `{` / `}` counts; report on the last unmatched brace line if unbalanced.

### 3. Undocumented property in binding (severity=2, warning)
For each property in a node with `compatible`:
- If NOT in standard DT keywords AND NOT in binding's `properties:` (following $ref) → warn

### 4. Missing required properties (severity=2, warning)
Extract `required:` list from binding YAML. For any missing required property, warn on the `compatible` line.

```bash
# Extract required list:
awk '/^required:/{found=1; next} found && /^  - /{print $2; next} found && /^[^ ]/{exit}' binding.yaml
```

## LSP format
```json
{"jsonrpc":"2.0","method":"textDocument/publishDiagnostics","params":{"uri":"...","diagnostics":[{"range":{"start":{"line":5,"character":0},"end":{"line":5,"character":100}},"severity":1,"message":"Missing semicolon"}]}}
```

## Call site
In the main loop, after `DOC_TEXT["$uri"]="$text"` for both `didOpen` and `didChange`:
```bash
publish_diagnostics "$uri" "$text"
```

## TDD
Study `tests/lsts/lsts` for diagnostics API first. Write tests for:
1. Missing semicolon → error diagnostic
2. Unclosed `{` → error diagnostic
3. Known property not in binding → warning
4. Missing required property → warning
5. Clean document → empty diagnostics array

Use real Linux DTS files from `tests/linux/` where possible; create minimal `.dts` fixtures for error cases.

## Commit
```
git commit -m "feat: implement publishDiagnostics for syntax errors and binding validation"
git push fork work:main
```
