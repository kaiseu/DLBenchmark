#! /bin/bash

## Prepare the dataset based on the configuration

CURRENT_DIR=$( cd $(BASH_SOURCE[0]) && pwd )

LOCAL_CONF_FILE=${CURRENT_DIR}/../conf/localSetting.conf

## Load Local Configurations
if [[ -f ${LOCAL_CONF_FILE} ]]; then
	echo "==============================================================================================="
	echo "Loading Local Configuration file from: ${LOCAL_CONF_FILE}..."
	source "${LOCAL_CONF_FILE}"
else
	echo "==============================================================================================="
	echo "Local Configuration file:${LOCAL_CONF_FILE} does not exist, exiting..."
	exit -1
fi

## Whether to download Source dataset images?
INT_SERVER="bdpa-gateway.sh.intel.com:8088/dataset"
EXT_SERVER="http://host.robots.ox.ac.uk/pascal/VOC/"
TIMEOUT=5
PASCAL_DATA_DIR=${TEMP_DATA_DIR}/pascal
COCO_DATA_DIR=${TEMP_DATA_DIR}/coco

if [[ ! -d ${PASCAL_DATA_DIR} ]]; then
	mkdir -p ${PASCAL_DATA_DIR}
fi

if [[ ! -d ${COCO_DATA_DIR} ]]; then
        mkdir -p ${COCO_DATA_DIR}
fi

if [[ x${DATA_SET} == "xvoc0712" ]]; then
	if [[ ! -d ${PASCAL_DATA_DIR}/VOCdevkit ]]; then
		DOWNLOAD_PASCAL ${INT_SERVER} ${PASCAL_DATA_DIR} 0
		if [[ $? != 0 ]]; then
			DOWNLOAD_PASCAL ${EXT_SERVER} ${PASCAL_DATA_DIR} 1
		fi
	else
		echo "Dataset ${DATA_SET} already exists in ${PASCAL_DATA_DIR}/VOCdevkit, will not download again."
	fi
fi






if [[ x${DATA_SET} == "xvoc0712" ]] && [[ ! -d ${PASCAL_DATA_DIR}/VOCdevkit ]]; then
	RET_CODE=`curl -I -s --connect-timeout ${TIMEOUT} ${INT_SERVER} -w %{http_code} | tail -n1`
	if [[ x${RET_CODE} == "x200" ]]; then
		echo "Begin to download ${DATA_SET} dataset from ${INT_SERVER}/PASCAL..."
		cd ${PASCAL_DATA_DIR}
		curl -OOO ${INT_SERVER}/PASCAL/{VOCtest_06-Nov-2007.tar,VOCtrainval_06-Nov-2007.tar,VOCtrainval_11-May-2012.tar}  
		echo "Download Done!"
		echo "==============================================================================================="
		echo "Extracting the tar files..."
		cat *.tar | tar -xvf - -i >> /dev/null 2>&1
		echo "Extract Done!"
		echo "==============================================================================================="
		cd -
	else
		RET_CODE=`curl -I -s --connect-timeout ${TIMEOUT} ${EXT_SERVER} -w %{http_code} | tail -n1`
		if [[ x${RET_CODE} == "x200" ]]; then
			echo "Begin to download ${DATA_SET} dataset from ${INT_SERVER}/PASCAL..."

		
	fi	

function DOWNLOAD_PASCAL(){
	SERVER=$1 ## the server from where to download
	DEST_DIR=$2 ## the dir to save the downloaded files
	IS_INT=$3 ## Flag, is the server Internal or External? 0 represents Internal, 1 represents External. 
	RET_CODE=`curl -I -s --connect-timeout ${TIMEOUT} ${SERVER} -w %{http_code} | tail -n1`
	if [[ x${RET_CODE} == "x200" ]]; then
		cd ${DEST_DIR}
		echo "==============================================================================================="
		echo "Begin to download ${DATA_SET} dataset from ${SERVER}/PASCAL..."
		if [[ x${IS_INT} == "x0" ]]; then
			curl -OOO ${SERVER}/PASCAL/{VOCtest_06-Nov-2007.tar,VOCtrainval_06-Nov-2007.tar,VOCtrainval_11-May-2012.tar}
		elif [[ x${IS_INT} == "x1" ]]; then
			curl -O ${SERVER}/voc2007/VOCtest_06-Nov-2007.tar
			curl -O ${SERVER}/voc2007/VOCtrainval_06-Nov-2007.tar
			curl -O ${SERVER}/voc2012/VOCtrainval_11-May-2012.tar
		else
			echo "The third Input can only be 0 or 1, 0 represents Internal server, 1 represents External server."
			exit -2
		fi
		
		echo "Download Done!"
		echo "==============================================================================================="
		echo "Extracting the tar files..."
		cat *.tar | tar -xvf - -i >> /dev/null 2>&1
                echo "Extract Done!"
                echo "==============================================================================================="
                cd -
	else
		echo "Can not connect to Server: ${SERVER}, please check and try again. Exiting..."
		exit -3
	fi
}

