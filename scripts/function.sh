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

function CHECK_EXIST_EXEC(){
## Check if a shell script file exists and is executable.
	SCRIPT_PATH=$1

	if [[ ! -f ${SCRIPT_PATH} ]]; then
		DATE_PREFIX "ERROR" "Script: ${SCRIPT_PATH} does not exist, exiting ..."
		exit -1 
	elif [[ ! -x ${SCRIPT_PATH} ]]; then
		chmod +x ${SCRIPT_PATH}
	fi
}
