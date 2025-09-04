#!/bin/bash
find moby -type f -exec sed -i.bak 's/bookworm/trixie/g' {} +
find moby -type f -exec sed -i 's/golang:1.24.7-trixie/golang:1.25.1-trixie/g' {} +
