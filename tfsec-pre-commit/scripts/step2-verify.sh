#!/bin/bash

# Verify that pre-commit has been hooked
[ -f ./demo/.git/hooks/pre-commit ] && echo "done"