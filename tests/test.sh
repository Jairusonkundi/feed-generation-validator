#!/bin/bash
set -e

# Establish the verifier log directory safely
mkdir -p /logs/verifier

# Use uv run to execute the pytest suite to satisfy sandbox rules
if uvx pytest /tests/test_outputs.py; then
    echo "1" > /logs/verifier/reward.txt
else
    echo "0" > /logs/verifier/reward.txt
fi