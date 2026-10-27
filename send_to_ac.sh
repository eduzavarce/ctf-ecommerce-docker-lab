#!/bin/bash

source "./load-env-variables.sh"
rsync -avz ./ "$CA_MACHINE_USER"@"$CA_MACHINE_ADDRESS":~/repo/
