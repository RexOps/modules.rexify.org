#!/bin/sh

rm -rf /var/tmp/rex-recipes
cd /var/tmp
git clone https://github.com/RexOps/rex-recipes.git

hypnotoad -f bin/module
