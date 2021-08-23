#!/bin/bash

# reset all submodule to discard all changes

git submodule foreach --recursive git reset --hard
