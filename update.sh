#!/bin/bash

rsync -avP ../linux-book/book/html/* .
lazyg 'update and publish'
