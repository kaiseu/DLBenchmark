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

function SEQ_DATASET_REPLICA(){
	ORG_DATASET_DIR=$1
	DATA_REPLICA=$2

	SUFFIX=".seq"

	ORG_SIZE=`du ${ORG_DATASET_DIR} | awk -F " " '{ print $1 }'`
	EST_SIZE=$(( ORG_SIZE * DATA_REPLICA / 1024 ))
	DATE_PREFIX "INFO" "Original dataset is about $((ORG_SIZE/1024)) MB, with replica ${DATA_REPLICA}, it will take about ${EST_SIZE} MB disk space."
	DATE_PREFIX "INFO" "Creating dataset replica ..."

	
	for line in `ls -A ${ORG_DATASET_DIR}`
	do
		for (( i=1;i<$DATA_REPLICA;i++ ));
		do
			NEW_NAME="`echo ${line} | awk 'BEGIN{FS=OFS="."}{$NF=""; NF--; print}'`_${i}${SUFFIX}"
			cp -r ${ORG_DATASET_DIR}/${line} ${ORG_DATASET_DIR}/${NEW_NAME}
		done
	done

	DATE_PREFIX "INFO" "Creating done!"
}
