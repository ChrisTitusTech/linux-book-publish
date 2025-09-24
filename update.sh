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

mdbook build "${HOME_PATH}/github/linux-book"
rsync -avP "${HOME_PATH}/github/linux-book/book/html/" "${HOME_PATH}/github/linux-book-publish/"
git add .
git commit -m "Update book content"
git push
