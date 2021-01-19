#!/bin/bash
# pull upstream master branch into local master branch
git checkout master
git pull git@github.com:lightenna/devops-workstream.git master
git push