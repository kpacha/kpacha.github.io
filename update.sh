#!/bin/bash
git checkout editor -- web
cp -rp web/* .
rm -rf web
git reset HEAD web
git status
