#!/bin/bash
mdbook build /home/titus/github/linux-book
rsync -avP /home/titus/github/linux-book/book/html/* /home/titus/github/linux-book-publish/
git add .
git commit -m "Update book content"
git push
