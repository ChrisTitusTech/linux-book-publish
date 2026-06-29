#!/bin/bash

# Detect operating system and set appropriate home path
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    HOME_PATH="/home/titus"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    HOME_PATH="/Users/titus"
else
    echo "Unsupported operating system: $OSTYPE"
    exit 1
fi

BOOK_DIR="${HOME_PATH}/github/linux-book"
PUBLISH_DIR="${HOME_PATH}/github/linux-book-publish"
BOOK_TOML="${BOOK_DIR}/book.toml"
BOOK_TOML_BACKUP="${BOOK_DIR}/book.toml.backup"

# Backup original book.toml
cp "$BOOK_TOML" "$BOOK_TOML_BACKUP"

# Create HTML-only book.toml (no PDF or EPUB)
cat > "$BOOK_TOML" << 'EOF'
[book]
authors = ["Chris Titus"]
description = "A practical, no-fluff guide to Linux for real desktop users. Learn how Linux works under the hood, set up your system with confidence, and solve everyday problems from boot to backups."
language = "en"
src = "src"
title = "The Linux Desktop Guide"

[output.html]
additional-css = ["./theme/catppuccin.css", "./theme/book.css", "./theme/last-changed.css"]
admonitions = true
default-theme = "latte"
definition-lists = true
preferred-dark-theme = "frappe"
smart-punctuation = true
fold.enable = true
fold.level = 2

[output.html.print]
enable = false

[preprocessor.last-changed]
command = "mdbook-last-changed"
renderer = ["html"]

[preprocessor.toc]
command = "mdbook-toc"
renderer = ["html"]
max-level = 4
EOF

# Build mdbook
mdbook build "$BOOK_DIR"

# Restore original book.toml
mv "$BOOK_TOML_BACKUP" "$BOOK_TOML"

rsync -avP "${BOOK_DIR}/book/" "${PUBLISH_DIR}/" --exclude=book/

# Keep the generated HTML site publish-only. The source book still uses the
# shared CSS for PDF and EPUB, so fix the copied HTML CSS after each rebuild.
PUBLISH_DIR="$PUBLISH_DIR" python - << 'PY'
import os
from pathlib import Path

css_path = Path(os.environ["PUBLISH_DIR"]) / "theme/book.css"
css = css_path.read_text()
css = css.replace(
    """
.content pre {
  margin: 0;
  background: transparent !important;
}
""",
    "",
)
css = css.replace(
    """.content pre code {
  display: block;
  padding: 0.9rem 1rem;
  color: #d7e5ff;
}""",
    """.content pre code {
  display: block;
  overflow-x: auto;
  padding: 0.9rem 1rem;
  background: #121823;
  color: #d7e5ff;
}""",
)
light_mode_code_css = """

.latte .content pre code,
.latte .content pre .hljs {
  background: #121823;
  color: #d7e5ff;
}

.latte .content pre .hljs-keyword,
.latte .content pre .hljs-name,
.latte .content pre .hljs-variable,
.latte .content pre .hljs-variable.language_ {
  color: #d6a3f0;
}

.latte .content pre .hljs-built_in,
.latte .content pre .hljs-doctag,
.latte .content pre .hljs-emphasis,
.latte .content pre .hljs-strong {
  color: #f09698;
}

.latte .content pre .hljs-type,
.latte .content pre .hljs-title.class_,
.latte .content pre .hljs-selector-tag {
  color: #f0d69a;
}

.latte .content pre .hljs-literal,
.latte .content pre .hljs-number,
.latte .content pre .hljs-meta,
.latte .content pre .hljs-variable.constant_ {
  color: #f5b08a;
}

.latte .content pre .hljs-operator,
.latte .content pre .hljs-link {
  color: #a6e4ee;
}

.latte .content pre .hljs-punctuation,
.latte .content pre .hljs-params,
.latte .content pre .hljs-subst {
  color: #c6d0f5;
}

.latte .content pre .hljs-property,
.latte .content pre .hljs-tag,
.latte .content pre .hljs-bullet,
.latte .content pre .hljs-formula,
.latte .content pre .hljs-selector-class,
.latte .content pre .hljs-selector-pseudo {
  color: #9adbd2;
}

.latte .content pre .hljs-regexp {
  color: #f5c9ea;
}

.latte .content pre .hljs-string,
.latte .content pre .hljs-char.escape_,
.latte .content pre .hljs-attribute,
.latte .content pre .hljs-code,
.latte .content pre .hljs-quote {
  color: #b7df9d;
}

.latte .content pre .hljs-symbol,
.latte .content pre .hljs-template-tag,
.latte .content pre .hljs-template-variable {
  color: #f2caca;
}

.latte .content pre .hljs-title,
.latte .content pre .hljs-title.function_,
.latte .content pre .hljs-attr,
.latte .content pre .hljs-section,
.latte .content pre .hljs-selector-id {
  color: #a4bdf7;
}

.latte .content pre .hljs-comment {
  color: #aeb7d4;
}

.latte .content pre .hljs-addition {
  color: #b7df9d;
  background: rgba(183, 223, 157, 0.15);
}

.latte .content pre .hljs-deletion {
  color: #f09698;
  background: rgba(240, 150, 152, 0.15);
}
"""
if ".latte .content pre .hljs-keyword" not in css:
    css = css.replace("\n.print-toc ul {", light_mode_code_css + "\n.print-toc ul {")
css_path.write_text(css)
PY

git -C "$PUBLISH_DIR" add .
git -C "$PUBLISH_DIR" commit -m "Update book content"
git -C "$PUBLISH_DIR" push
