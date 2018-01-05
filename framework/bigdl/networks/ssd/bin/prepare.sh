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
INT_PASCAL_SERVER="bdpa-gateway.sh.intel.com:8088/dataset/PASCAL"
INT_COCO_SERVER="bdpa-gateway.sh.intel.com:8088/dataset/COCO"
EXT_PASCAL_SERVER="http://host.robots.ox.ac.uk/pascal/VOC/"
EXT_COCO_SERVER="http://images.cocodataset.org/zips/"
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
		DOWNLOAD_PASCAL ${INT_PASCAL_SERVER} ${PASCAL_DATA_DIR} 0
		if [[ $? != 0 ]]; then
			DOWNLOAD_PASCAL ${EXT_PASCAL_SERVER} ${PASCAL_DATA_DIR} 1
		fi
	else
		echo "Dataset ${DATA_SET} already exists in ${PASCAL_DATA_DIR}/VOCdevkit, will not download again."
	fi
elif [[ x${DATA_SET} == "xcoco" ]]; then
	if [[ ! -d ${COCO_DATA_DIR}/images ]]; then
		DOWNLOAD_COCO ${INT_COCO_SERVER} ${COCO_DATA_DIR} 0
		if [[ $? != 0 ]]; then
                        DOWNLOAD_COCO ${EXT_COCO_SERVER} ${COCO_DATA_DIR} 1
                fi
	else
                echo "Dataset ${DATA_SET} already exists in ${COCO_DATA_DIR}/images, will not download again."
        fi
else
	echo "Dataset only can be voc0712 or coco currently! Exiting..."
	exit -4
fi




function DOWNLOAD_PASCAL(){
	SERVER=$1 ## the server from where to download
	DEST_DIR=$2 ## the dir to save the downloaded files
	IS_INT=$3 ## Flag, is the server Internal or External? 0 represents Internal, 1 represents External. 
	TIMEOUT="5"
	RET_CODE=`curl -I -s --connect-timeout ${TIMEOUT} ${SERVER} -w %{http_code} | tail -n1`
	if [[ x${RET_CODE} == "x200" ]]; then
		cd ${DEST_DIR}
		echo "==============================================================================================="
		echo "Begin to download ${DATA_SET} dataset from ${SERVER} ..."
		if [[ x${IS_INT} == "x0" ]]; then
			curl -OOO ${SERVER}/{VOCtest_06-Nov-2007.tar,VOCtrainval_06-Nov-2007.tar,VOCtrainval_11-May-2012.tar}
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


function DOWNLOAD_COCO(){
        SERVER=$1 ## the server from where to download
        DEST_DIR=$2 ## the dir to save the downloaded files
        IS_INT=$3 ## Flag, is the server Internal or External? 0 represents Internal, 1 represents External.
        TIMEOUT="5"
        RET_CODE=`curl -I -s --connect-timeout ${TIMEOUT} ${SERVER} -w %{http_code} | tail -n1`
	if [[ x${RET_CODE} == "x200" ]]; then
                cd ${DEST_DIR}
                echo "==============================================================================================="
                echo "Begin to download ${DATA_SET} dataset from ${SERVER} ..."
		if [[ x${IS_INT} == "x0" ]]; then
			## Get images
			curl -OOOO ${SERVER}/{train2014.zip,val2014.zip,test2014.zip,test2015.zip}
			## Get annotations
			curl -OOOOO ${SERVER}/{image_info_test2014.zip,image_info_test2015.zip,instances_minival2014.json.zip,instances_train-val2014.zip,instances_valminusminival2014.json.zip}
		elif [[ x${IS_INT} == "x1" ]]; then
			## Get images
			curl -OOOO ${SERVER}/{train2014.zip,val2014.zip,test2014.zip,test2015.zip}
			## Get annotations
			curl -O http://msvocds.blob.core.windows.net/annotations-1-0-4/image_info_test2014.zip
			curl -O http://msvocds.blob.core.windows.net/annotations-1-0-4/image_info_test2015.zip
			curl -O http://msvocds.blob.core.windows.net/annotations-1-0-3/instances_train-val2014.zip
			curl -O http://www.cs.berkeley.edu/~rbg/faster-rcnn-data/instances_minival2014.json.zip
			curl -O http://www.cs.berkeley.edu/~rbg/faster-rcnn-data/instances_valminusminival2014.json.zip
		else
                        echo "The third Input can only be 0 or 1, 0 represents Internal server, 1 represents External server."
                        exit -2
                fi

		echo "Download Done!"
                echo "==============================================================================================="
                echo "Extracting the zip files..."
		unzip "*.zip" >> /dev/null 2>&1
		echo "Extract Done!"
                echo "==============================================================================================="
                cd -
        else
                echo "Can not connect to Server: ${SERVER}, please check and try again. Exiting..."
                exit -3
        fi
}
