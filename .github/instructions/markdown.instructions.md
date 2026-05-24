---
applyTo: '**/*.md'
description: 'Comprehensive Markdown best practices and formatting rules, aligned with markdownguide.org, markdownlint, and CommonMark spec 0.31.2.'
---

# Markdown Documentation & Formatting Guide

## Mission

Write Markdown that is:

- **Correct**: Passes all [markdownlint](https://github.com/DavidAnson/markdownlint) rules and aligns with [CommonMark 0.31.2](https://spec.commonmark.org/0.31.2/).
- **Consistent**: Uses uniform styles for headings, lists, code, and emphasis.
- **Clear**: Easy to read, scan, and maintain.
- **Accessible**: Usable by all, including those with assistive technologies.

## Core Principles

### 1. Consistency

- Use ATX-style headings (`#`) only.
- Use `-` for unordered lists.
- - Use `**bold**` and `*italic*` consistently (avoid `__` or `_` for emphasis to prevent conflicts with code).
- Always use fenced code blocks with language identifiers.
- Match existing style when editing.

### 2. Clarity

- Use descriptive headings and logical hierarchy (H1 → H2 → H3).
- Short paragraphs (3–5 sentences).
- Prefer active voice and concise language.
- Use lists and subheadings for structure.
- Provide examples for clarity.

### 3. Correctness

- Follow all Markdown syntax rules and linting standards.
- Validate all links and images.
- Specify language for all code blocks.
- Pass all markdownlint rules.

### 4. Accessibility

- Use descriptive link text (not "click here").
- Provide meaningful alt text for images.
- Use proper heading hierarchy (no skipped levels).
- Use tables responsibly; ensure header rows exist and avoid nested tables.

## CommonMark Compliance Highlights

- **Headings**: ATX (`#`) headings use 1–6 `#` followed by a space. Setext headings (`===`/`---`) are allowed by spec but discouraged for consistency.
- **Thematic breaks**: 3+ matching `-`, `_`, or `*` on a line with only spaces/tabs otherwise.
- **Code blocks**: Use 3+ backticks or tildes for fences. Info string (language) after opening fence; do not include backticks in info string.

    ✓ **Correct**: ` ```javascript `

    ✗ **Incorrect**: ` ```[javascript] `

- **Lists**: Bullets (`-`, `+`, `*`) or ordered (`1.`, `1)`). Indent sublists to content column.
- **Links/Images**: `[text](url)` or reference style. No whitespace before `(` or `[`. Images: `![alt](src "title")` with non-empty alt text.
- **Autolinks**: Use `<URL>` or `<email@example.com>`. Bare URLs like `https://example.com` are not auto-linked; use link syntax instead.
- **Emphasis**: `*`/`_` for emphasis, `**`/`__` for strong. `_` not for intraword emphasis.
- **HTML**: Inline HTML allowed but avoid unless necessary.

## Editor & Linting Setup

```json
// .vscode/settings.json
{
  "files.trimTrailingWhitespace": true,
  "files.insertFinalNewline": true,
  "editor.formatOnSave": true,
  "[markdown]": {
    "editor.defaultFormatter": "DavidAnson.vscode-markdownlint",
    "editor.wordWrap": "on"
  }
}
```

## Templates & Patterns

- **Start with a template** (Guide, API, README).
- **Use pattern library** for headings, lists, code, links, images, and tables.
- **Validate as you write** with markdownlint.

## Validation Checklist

- [ ] ATX headings use 1–6 `#` followed by a space.
- [ ] Only one H1 per document.
- [ ] Fenced code blocks specify a language and use matching fence characters.
- [ ] No trailing whitespace; file ends with a single newline.
- [ ] Lists use consistent markers and indentation.
- [ ] Links and images use descriptive text/alt.
- [ ] No bare URLs; use link syntax.
- [ ] No skipped heading levels.
- [ ] Passes all markdownlint rules.

## Additional Resources

- [Markdown Guide](https://www.markdownguide.org/)
- [CommonMark Spec](https://spec.commonmark.org/0.31.2/)
- [markdownlint Rules](https://github.com/DavidAnson/markdownlint/blob/main/doc/Rules.md)

---

*Follow these rules to ensure your Markdown is readable, maintainable, and standards-compliant.*

---

<!-- End of Markdown Documentation & Formatting Guide Instructions --> 