#!/bin/bash

source "./load-env-variables.sh"
rsync -avz ./ "$SERVER_USER"@"$SERVER_ADDRESS":~/labs/ctf-ecommerce-docker-lab
