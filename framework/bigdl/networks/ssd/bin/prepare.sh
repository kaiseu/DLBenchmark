#! /bin/bash

## Prepare the dataset based on the configuration

CURRENT_DIR=$( cd $( dirname ${BASH_SOURCE[0]} ) && pwd )

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
INT_PASCAL_SERVER="bdpa-gateway.sh.intel.com:8088/dataset/PASCAL/"
INT_COCO_SERVER="bdpa-gateway.sh.intel.com:8088/dataset/COCO/"
EXT_PASCAL_SERVER="http://host.robots.ox.ac.uk/pascal/VOC/"
EXT_COCO_SERVER="http://images.cocodataset.org/zips/"
PASCAL_DATA_DIR=${TEMP_DATA_DIR}/data/pascal
COCO_DATA_DIR=${TEMP_DATA_DIR}/data/coco


function DOWNLOAD_PASCAL(){
	SERVER=$1 ## the server from where to download
	DEST_DIR=$2 ## the dir to save the downloaded files
	IS_INT=$3 ## Flag, is the server Internal or External? 0 represents Internal, 1 represents External. 
	TIMEOUT="5"
	RET_CODE=`curl -L -I -s --connect-timeout ${TIMEOUT} ${SERVER} -w %{http_code} | tail -n1`
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
                cd - >> /dev/null 2>&1
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
        RET_CODE=`curl -L -I -s --connect-timeout ${TIMEOUT} ${SERVER} -w %{http_code} | tail -n1`
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
		mkdir images/
		mv train2014/ val2014/ test2014/ test2015 images/
		echo "Images have been moved to: ${DEST_DIR}/images"
		mv instances_minival2014.json annotations/
		mv instances_valminusminival2014.json annotations/
		echo "Annotations have been moved to: ${DEST_DIR}/annotations"
                cd - >> /dev/null 2>&1
        else
                echo "Can not connect to Server: ${SERVER}, please check and try again. Exiting..."
                exit -3
        fi
}


function COCO_SPLIT_ANNO(){
## Split Imageset and Annotations
	if [[ "$#" -ne 1 ]] || ! [ -d "$1" ]; then
		echo "Uage: $0 DIRECTORY"
		exit -5
	fi
	DATA_DIR=$1 ## coco dataset path
	PY_BATCH_SPLIT=${CURRENT_DIR}/../data/coco/PythonAPI/scripts/batch_split_annotation.py
	if [[ -f ${PY_BATCH_SPLIT} ]]; then
		echo "==============================================================================================="
		echo "Calling Python script: ${PY_BATCH_SPLIT} ..."
		python ${PY_BATCH_SPLIT} ${DATA_DIR}
		echo "Split annotations done!"
	else
		echo "Python script: ${PY_BATCH_SPLIT} does not exist, exiting..."
		exit -6
	fi
}


if [[ x${DATA_SET} == "xvoc0712" ]]; then
        ## Download and Extract PASCAL VOC dataset
        if [[ ! -d ${PASCAL_DATA_DIR}/VOCdevkit ]]; then
		if [[ ! -d ${PASCAL_DATA_DIR} ]]; then
  		      mkdir -p ${PASCAL_DATA_DIR}
		fi
                DOWNLOAD_PASCAL ${INT_PASCAL_SERVER} ${PASCAL_DATA_DIR} 0 ## From Internal Server
                if [[ $? != 0 ]]; then
                        DOWNLOAD_PASCAL ${EXT_PASCAL_SERVER} ${PASCAL_DATA_DIR} 1 ## From External Server
                fi
        else
                echo "Dataset ${DATA_SET} already exists in ${PASCAL_DATA_DIR}/VOCdevkit, will not download again."
        fi
elif [[ x${DATA_SET} == "xcoco" ]]; then
        ## Download and Extract COCO dataset
        if [[ ! -d ${COCO_DATA_DIR}/images ]] || [[ ! -d ${COCO_DATA_DIR}/annotations ]]; then
		if [[ ! -d ${COCO_DATA_DIR} ]]; then
			mkdir -p ${COCO_DATA_DIR}
		fi
                DOWNLOAD_COCO ${INT_COCO_SERVER} ${COCO_DATA_DIR} 0 ## From Internal Server
                if [[ $? != 0 ]]; then
                        DOWNLOAD_COCO ${EXT_COCO_SERVER} ${COCO_DATA_DIR} 1 ## From External Server
                fi
        else
                echo "Dataset ${DATA_SET} already exists in ${COCO_DATA_DIR}/images, will not download again."
        fi
        ## Split Imageset and Annotations
	if [[ ! -d ${COCO_DATA_DIR}/Annotations ]]; then
	        COCO_SPLIT_ANNO ${TEMP_DATA_DIR}
	else
		echo "Splited ${DATA_SET} annotations already exists in ${COCO_DATA_DIR}/Annotations, will not split again."
	fi
else
        echo "Dataset only can be voc0712 or coco currently! Exiting..."
        exit -4
fi
