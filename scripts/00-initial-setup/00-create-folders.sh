#!/bin/bash

folders=(
	/srv/wordpress
	)
for folder in "${folders[@]}"; do
    sudo mkdir -p "$folder"
done

sudo chown -R www-data:www-data /srv/wordpress