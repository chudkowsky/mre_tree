#!/bin/bash

source snos-env/bin/activate

cairo-compile mmr_cairo0/main.cairo --output mmr_cairo0/main.json

cairo-run --program mmr_cairo0/main.json --layout recursive_with_poseidon --print_output