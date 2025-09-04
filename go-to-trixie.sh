#!/bin/bash
find moby -type f -exec sed -i.bak 's/bookworm/trixie/g' {} +
find . -type f -exec sed -i 's/golang:1.25.1-trixie/golang:1.25.1-trixie/g' {} +
find . -type f -exec sed -i 's/1.25.1/1.25.1/g' {} +
grep -r -l "golang:1.25.1-trixie" .
