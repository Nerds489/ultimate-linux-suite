# Ultimate Linux Suite - Local Build System
#
# Usage:
#   make deb    - Build .deb package
#   make rpm    - Build .rpm package
#   make all    - Build both packages
#   make clean  - Clean build artifacts
#

.PHONY: all deb rpm clean help

# Default target
all:
	./build.sh all

deb:
	./build.sh deb

rpm:
	./build.sh rpm

clean:
	./build.sh clean

help:
	./build.sh --help
