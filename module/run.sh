#!/bin/sh

rm -rf /var/tmp/rex-recipes
cd /var/tmp
git clone https://github.com/RexOps/rex-recipes.git
cd /var/project

hypnotoad -f bin/module
