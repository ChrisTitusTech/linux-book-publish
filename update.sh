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
  color: #d7e5ff;
}""",
)
css_path.write_text(css)
PY

git -C "$PUBLISH_DIR" add .
git -C "$PUBLISH_DIR" commit -m "Update book content"
git -C "$PUBLISH_DIR" push
