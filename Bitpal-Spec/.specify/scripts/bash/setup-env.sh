#!/usr/bin/env bash
# Project-specific environment setup for Bitpal
# Usage: source .specify/scripts/bash/setup-env.sh

# Detect Bitpal-Spec directory (where .specify folder lives)
if [[ -n "${BASH_SOURCE[0]}" ]]; then
    # When sourced, use BASH_SOURCE to find script location
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    BITPAL_SPEC_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"
else
    # Fallback: assume we're in Bitpal-Spec directory
    BITPAL_SPEC_DIR="$(pwd)"
fi

# Set specs directory to Bitpal-Spec/specs
export SPECIFY_SPECS_DIR="$BITPAL_SPEC_DIR/specs"

echo "[Bitpal] Environment configured:"
echo "  BITPAL_SPEC_DIR=$BITPAL_SPEC_DIR"
echo "  SPECIFY_SPECS_DIR=$SPECIFY_SPECS_DIR"
