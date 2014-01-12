#!/bin/bash
git checkout editor -- web
mv web/* .
rm -rf web
git reset HEAD web
git status
