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
enable = true
page-break = true

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

rsync -avP "${BOOK_DIR}/book/html/" "${HOME_PATH}/github/linux-book-publish/"
git add .
git commit -m "Update book content"
git push
