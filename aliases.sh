#!/bin/sh

# NNDI Ltd, 2024
#
# Somewhat useful aliases for NNDI development environments


## Checkout and Build a PR - this requires taskfile.dev to be installed and a task defined as build-pr
# An alternative implementation could look like this below:
# `alias cpr="gh pr checkout $1 && task build"`
alias cpr="task build-pr -- "
