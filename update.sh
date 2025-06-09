#!/bin/bash

rsync -avP ../linux-book/book/html/* .
git add .
git commit -m "Update book content"
git push
