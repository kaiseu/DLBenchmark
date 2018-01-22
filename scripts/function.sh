#! /bin/bash

function DATE_PREFIX(){
        INFO_LEVEL=$1
        MESSAGE=$2
        echo -e "`date '+%Y-%m-%d %H:%M:%S'` ${INFO_LEVEL}  ${MESSAGE}"
}

function ADD_DATE() {
        eval INFO_LEVEL=$1
        while IFS= read -r line; do
		echo "`date +'%Y-%m-%d %H:%M:%S'` ${INFO_LEVEL}  $line"
        done
}

