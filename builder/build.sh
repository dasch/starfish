#!/bin/bash
#
# Builds a specified Git repository with Docker.
#
# $1 - The URL of a Git repository.
# $2 - A tag that should be added to the image.

exec docker build -t $2 $1
