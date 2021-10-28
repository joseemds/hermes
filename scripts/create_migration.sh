#!/usr/bin/env bash

file_name=$1
project_root=$(git rev-parse --show-toplevel)

timestamp=$(date +%Y%m%d%H%M%S)


if [ -d "$project_root/resources/schema-migrations" ]; then
	file="${timestamp}_${file_name}.sql"
	echo "Creating ${file} "
	touch $project_root/resources/schema-migrations/$file

else
	echo "Was expecting the $project_root/resources/schema-migrations to exists"; exit 1;

fi


