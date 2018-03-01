#! /bin/bash
## Prepare the dataset based on the configuration
CURRENT_DIR=$( cd $( dirname ${BASH_SOURCE[0]} ) && pwd )

## Import functions
if test -z ${DLBENCHMARK_FUNCS}; then
	DLBENCHMARK_FUNCS=${CURRENT_DIR}/../../../../../scripts/function.sh
fi
if [[ ! -x ${DLBENCHMARK_FUNCS} ]]; then
	chmod +x ${DLBENCHMARK_FUNCS}
fi
source ${DLBENCHMARK_FUNCS}

## Load Local Configurations
LOCAL_CONF_FILE=${CURRENT_DIR}/../conf/localSetting.conf
if [[ -f ${LOCAL_CONF_FILE} ]]; then
	echo "****************************************************************"
	DATE_PREFIX "INFO" "Loading Local Configuration file from: ${LOCAL_CONF_FILE}..."
        source "${LOCAL_CONF_FILE}"
	DATE_PREFIX "INFO" "Loading Done!"
else
	DATE_PREFIX "ERROR" "Local Configuration file:${LOCAL_CONF_FILE} does not exist, exiting..."
	exit -1
fi

## DO Not Edit, If You NOT Know What You are doing!
INT_PASCAL_SERVER="bdpa-gateway.sh.intel.com:8088/dlbenchmark/dataset/PASCAL/"
INT_COCO_SERVER="bdpa-gateway.sh.intel.com:8088/dlbenchmark/dataset/COCO/"
INT_BASE_MODEL_SERVER="bdpa-gateway.sh.intel.com:8088/dlbenchmark/models/ssd"
INT_BASE_MODEL_SERVER_CAFFE=${INT_BASE_MODEL_SERVER}/base_model/caffe
INT_BASE_MODEL_SERVER_BIGDL=${INT_BASE_MODEL_SERVER}/base_model/bigdl
INT_BASE_MODEL_SERVER_TF=${INT_BASE_MODEL_SERVER}/base_model/tensorflow
EXT_BASE_MODEL_SERVER_BIGDL="https://s3-ap-southeast-1.amazonaws.com/bigdl-models/object-detection"
EXT_PASCAL_SERVER="http://host.robots.ox.ac.uk/pascal/VOC/"
EXT_COCO_SERVER="http://images.cocodataset.org/zips/"
EXT_VGG_BASE_MODEL_300="https://doc-0o-30-docs.googleusercontent.com/docs/securesc/ha0ro937gcuc7l7deffksulhg5h7mbp1/4vekjv3i84tfbagshmm8fhibbemagvbk/1515369600000/09260862254863227534/*/0BzKzrI_SkD1_WVVTSmQxU0dVRzA?e=download"
EXT_VGG_BASE_MODEL_512="https://doc-0s-30-docs.googleusercontent.com/docs/securesc/ha0ro937gcuc7l7deffksulhg5h7mbp1/k0ivavusfo30kuo3un6ee1bjutqu8bnb/1515405600000/09260862254863227534/*/0BzKzrI_SkD1_ZDIxVHBEcUNBb2s?e=download"
EXT_ALEXNET_BASE_MODEL_300="https://storage.googleapis.com/drive-bulk-export-anonymous/20180108T064845Z/4133399871716478688/6e39bd56-ef20-422d-b7a6-ec6eed6ed5a4/1/a9eb60b0-f7f2-41a5-bc3f-a825ae0e6f16?authuser"
PASCAL_DATA_DIR="${TEMP_DATA_DIR}/data/PASCAL"
COCO_DATA_DIR="${TEMP_DATA_DIR}/data/COCO"
TEMP_SSD_MODEL_DIR=${TEMP_DATA_DIR}/models/ssd
TIMEOUT="5"


function DOWNLOAD_PASCAL(){
	local SERVER=$1 ## the server from where to download
	local DEST_DIR=$2 ## the dir to save the downloaded files
	local IS_INT=$3 ## Flag, is the server Internal or External? 0 represents Internal, 1 represents External. 

	DATE_PREFIX "INFO" "Testing the Network connection to: ${SERVER} ..."
	local RET_CODE=`curl -L -I -s --connect-timeout ${TIMEOUT} ${SERVER} -w %{http_code} | tail -n1`
	if [[ x${RET_CODE} == "x200" ]]; then
		DATE_PREFIX "INFO" "Network connection is OK!"
		cd ${DEST_DIR}
		DATE_PREFIX "INFO" "Begin to download ${DATA_SET} dataset from ${SERVER} ..."
		if [[ x${IS_INT} == "x0" ]]; then
			curl -OOO ${SERVER}/{VOCtest_06-Nov-2007.tar,VOCtrainval_06-Nov-2007.tar,VOCtrainval_11-May-2012.tar}
		elif [[ x${IS_INT} == "x1" ]]; then
			curl -O ${SERVER}/voc2007/VOCtest_06-Nov-2007.tar
			curl -O ${SERVER}/voc2007/VOCtrainval_06-Nov-2007.tar
			curl -O ${SERVER}/voc2012/VOCtrainval_11-May-2012.tar
		else
			DATE_PREFIX "INFO" "The third Input can only be 0 or 1, 0 represents Internal server, 1 represents External server."
			exit -2
		fi
	else
                DATE_PREFIX "INFO" "Can not connect to Server: ${SERVER}, please check and try again."
                return -3
        fi

	DATE_PREFIX "INFO" "Download Done!"
	DATE_PREFIX "INFO" "Extracting the tar files..."
	cat *.tar | tar -xvf - -i >> /dev/null 2>&1
        cd - >> /dev/null 2>&1
        DATE_PREFIX "INFO" "Extract Done!"
	echo "****************************************************************"
}


function DOWNLOAD_COCO(){
        local SERVER=$1 ## the server from where to download
        local DEST_DIR=$2 ## the dir to save the downloaded files
        local IS_INT=$3 ## Flag, is the server Internal or External? 0 represents Internal, 1 represents External.

	DATE_PREFIX "INFO" "Testing the Network connection to: ${SERVER} ..."
        local RET_CODE=`curl -L -I -s --connect-timeout ${TIMEOUT} ${SERVER} -w %{http_code} | tail -n1`
	if [[ x${RET_CODE} == "x200" ]]; then
		DATE_PREFIX "INFO" "Network connection is OK!"
	        cd ${DEST_DIR}
	        DATE_PREFIX "INFO" "Begin to download ${DATA_SET} dataset from ${SERVER} ..."
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
	                DATE_PREFIX "INFO" "The third Input can only be 0 or 1, 0 represents Internal server, 1 represents External server."
	                exit -2
	        fi
	
	else
                DATE_PREFIX "INFO" "Can not connect to Server: ${SERVER}, please check and try again."
                return -3
        fi

	DATE_PREFIX "INFO" "Download Done!"
        DATE_PREFIX "INFO" "Extracting the zip files..."
	unzip "*.zip" >> /dev/null 2>&1
	DATE_PREFIX "INFO" "Extract Done!"
	mkdir images/
	mv train2014/ val2014/ test2014/ test2015 images/
	DATE_PREFIX "INFO" "Images have been moved to: ${DEST_DIR}/images"
	mv instances_minival2014.json annotations/
	mv instances_valminusminival2014.json annotations/
	DATE_PREFIX "INFO" "Annotations have been moved to: ${DEST_DIR}/annotations"
        cd - >> /dev/null 2>&1
	echo "****************************************************************"
}


function COCO_SPLIT_ANNO(){
## Split Imageset and Annotations
	if [[ "$#" -ne 1 ]] || ! [ -d "$1" ]; then
		DATE_PREFIX "INFO" "Usage: $0 DIRECTORY"
		exit -5
	fi
	local DATA_DIR=$1 ## coco dataset path
	local PY_BATCH_SPLIT=${CURRENT_DIR}/../data/coco/PythonAPI/scripts/batch_split_annotation.py
	if [[ -f ${PY_BATCH_SPLIT} ]]; then
		echo "****************************************************************"
		DATE_PREFIX "INFO" "Building COCO API ..."
		cd ${CURRENT_DIR}/../data/coco/PythonAPI
		sh build_coco.sh >> /dev/null 2>&1
		if [[ $? ]]; then
			DATE_PREFIX "INFO" "Building Done!"
		else
			DATE_PREFIX "ERROR" "Building COCO API failed, it's possibly something wrong with Python! Exiting ..."
			exit -15
		fi

		DATE_PREFIX "INFO" "Calling Python script: ${PY_BATCH_SPLIT} ..."
		python ${PY_BATCH_SPLIT} ${DATA_DIR}
		DATE_PREFIX "INFO" "Split annotations done!"
	else
		DATE_PREFIX "INFO" "Python script: ${PY_BATCH_SPLIT} does not exist, exiting..."
		exit -6
	fi
}

## Downlaod Dataset Based on Local Configurations
function DOWNLOAD_DATA_SET(){
	if [[ x${DATA_SET} == "xVOC0712" ]]; then
	        ## Download and Extract PASCAL VOC dataset
	        if [[ ! -d ${PASCAL_DATA_DIR}/VOCdevkit ]]; then
			if [[ ! -d ${PASCAL_DATA_DIR} ]]; then
				DATE_PREFIX "INFO" "Creating Directory: ${PASCAL_DATA_DIR} ..."
	  			mkdir -p ${PASCAL_DATA_DIR}
			fi
			echo "INFO" "****************************************************************"
			DATE_PREFIX "INFO" "Will Download dataset: ${DATA_SET} ..."
	                DOWNLOAD_PASCAL ${INT_PASCAL_SERVER} ${PASCAL_DATA_DIR} 0 ## From Internal Server
	                if [[ $? != 0 ]]; then
	                        DOWNLOAD_PASCAL ${EXT_PASCAL_SERVER} ${PASCAL_DATA_DIR} 1 ## From External Server
				if [[ $? != 0 ]]; then
                                        DATE_PREFIX "INFO" "DownLoad dataset: ${DATA_SET} from External Server: ${EXT_PASCAL_SERVER} failed, possibly because of the network issue"
					exit -3
				fi
	                fi
	        else
	                DATE_PREFIX "INFO" "Dataset ${DATA_SET} already exists in ${PASCAL_DATA_DIR}/VOCdevkit, will not download again."
	        fi
	elif [[ x${DATA_SET} == "xCOCO" ]]; then
	        ## Download and Extract COCO dataset
	        if [[ ! -d ${COCO_DATA_DIR}/images ]] || [[ ! -d ${COCO_DATA_DIR}/annotations ]]; then
			if [[ ! -d ${COCO_DATA_DIR} ]]; then
				DATE_PREFIX "INFO" "Creating Directory: ${COCO_DATA_DIR} ..."
				mkdir -p ${COCO_DATA_DIR}
			fi
			echo "****************************************************************"
			DATE_PREFIX "INFO" "Will Download dataset: ${DATA_SET} ..."
	                DOWNLOAD_COCO ${INT_COCO_SERVER} ${COCO_DATA_DIR} 0 ## From Internal Server
	                if [[ $? != 0 ]]; then
	                        DOWNLOAD_COCO ${EXT_COCO_SERVER} ${COCO_DATA_DIR} 1 ## From External Server
				if [[ $? != 0 ]]; then
					DATE_PREFIX "INFO" "DownLoad dataset: ${DATA_SET} from External Server: ${EXT_COCO_SERVER} failed, possibly because of the network issue"
					exit -3
				fi
	                fi
	        else
	                DATE_PREFIX "INFO" "Dataset ${DATA_SET} already exists in ${COCO_DATA_DIR}/images, will not download again."
	        fi
	        ## Split Imageset and Annotations
		if [[ ! -d ${COCO_DATA_DIR}/Annotations ]]; then
		        COCO_SPLIT_ANNO ${TEMP_DATA_DIR}
		else
			DATE_PREFIX "INFO" "Splited ${DATA_SET} annotations already exists in ${COCO_DATA_DIR}/Annotations, will not split again."
		fi
	else
	        DATE_PREFIX "INFO" "Dataset only can be VOC0712 or COCO currently! Exiting..."
	        exit -4
	fi
}

function DOWNLOAD_BASE_MODEL(){
	local RESOLUTION=${IMAGE_RESOLUTION}
	if [[ x${BASE_MODEL} == "xVGGNet" ]]; then
		if [[ ! -f ${TF_CHECKPOINT_PATH}.zip ]]; then
			## Downlaod from Internal Server
			local INT_BASE_MODEL="${INT_BASE_MODEL_SERVER_TF}/${BASE_MODEL}/${CHECKPOINT_FILE_NAME}.zip"
			echo "****************************************************************"
			DATE_PREFIX "INFO" "Testing the Network connection to: ${INT_BASE_MODEL} ..."
			local RET_CODE=`curl -L -I -s --connect-timeout ${TIMEOUT} ${INT_BASE_MODEL} -w %{http_code} | tail -n1`
			if [[ x${RET_CODE} == "x200" ]]; then
				DATE_PREFIX "INFO" "Network connection is OK!"	
				DATE_PREFIX "INFO" "Begin to download base model: ${BASE_MODEL} with resolution: ${RESOLUTION}x${RESOLUTION} from Internal server: ${INT_BASE_MODEL} ..."
				SSD_BASE_MODEL_ROOT=`dirname ${TF_CHECKPOINT_PATH}`
				if [[ ! -d ${SSD_BASE_MODEL_ROOT} ]]; then
					mkdir -p ${SSD_BASE_MODEL_ROOT}
				fi
				cd ${SSD_BASE_MODEL_ROOT}
				echo "SSD_BASE_MODEL_ROOT:${SSD_BASE_MODEL_ROOT}"
				curl -O ${INT_BASE_MODEL}
				DATE_PREFIX "INFO" "Download Done!"
				DATE_PREFIX "INFO" "Base model have been saved to: ${TF_CHECKPOINT_PATH}.zip"

				DATE_PREFIX "INFO" "Unzip files..."
				unzip  -o ${TF_CHECKPOINT_PATH}.zip >> /dev/null 2>&1
				DATE_PREFIX "INFO" "Unzip Done!"
				cd - >> /dev/null 2>&1
			else
				DATE_PREFIX "ERROR" "Failed to connect to internal server: ${INT_BASE_MODEL}, need to download base model ${CHECKPOINT_FILE_NAME} manaually first! Exiting ..."
				exit -3
			fi
		else
			DATE_PREFIX "INFO" "Base model: ${BASE_MODEL} already exists in ${TF_CHECKPOINT_PATH}.zip, will not download again!"
			DATE_PREFIX "INFO" "Unzip files..."
			unzip -o ${TF_CHECKPOINT_PATH}.zip >> /dev/null 2>&1
			DATE_PREFIX "INFO" "Unzip Done!"
		fi
	else
		DATE_PREFIX "ERROR" "Currently only support base model VGGNet!"
		exit -4
	fi
}

function CLONE_TF(){ ## download source code
	SSD_BASE_MODEL_ROOT=`dirname ${TF_CHECKPOINT_PATH}`
	if [[ ! -d ${SSD_BASE_MODEL_ROOT} ]]; then
		mkdir -p ${SSD_BASE_MODEL_ROOT}
	fi
	if [[ ! -d ${TF_SSD_ROOT} ]]; then 
		if [[ ! -d ${TF_ROOT} ]]; then
			mkdir -p ${TF_ROOT}
		fi
		cd ${TF_ROOT}
		DATE_PREFIX "INFO" "Git clone SSD-Tensorflow source code ..."
		git clone https://github.com/kaiseu/SSD-Tensorflow
		if [[ ! $? == 0 ]]; then
			DATE_PREFIX "ERROR" "Clone failed!"
			cd - >> /dev/null 2>&1
			exit -1
		fi
		DATE_PREFIX "INFO" "Clone Done!"
		cd - >> /dev/null 2>&1
	else
		DATE_PREFIX "INFO" "SSD-Tensorflow source code already exists in: ${TF_SSD_ROOT}, will not clone again!"
	fi

	cd ${TF_SSD_ROOT}
	DATE_PREFIX "INFO" "Installing tensorflow ..."
	pip install tensorflow
	if [[ $? == 0 ]];then
		DATE_PREFIX "INFO" "Installation Done"
	else
		DATE_PREFIX "ERROR" "Installation failed, exiting ..."
		exit -1
	fi
}

function PREPARE_TF_Records(){ ## convert TF-Records
	DATE_PREFIX "INFO" "TF_SSD_ROOT is: ${TF_SSD_ROOT}"
	DATE_PREFIX "INFO" "DATAPATH is: ${DATAPATH}"
	DATE_PREFIX "INFO" "Output dir is: ${TF_SSD_Records}"

	if [[ `ls -A ${TF_SSD_Records}` = "" ]]; then ## if the dir is empty
		DATE_PREFIX "INFO" "Converting TF-Records ..."
		if [[ ! -d ${TF_SSD_Records} ]]; then
			mkdir -p ${TF_SSD_Records}
		fi

		cd ${TF_SSD_ROOT}
		python tf_convert_data.py --dataset_name=pascalvoc --dataset_dir=${DATAPATH} --output_name=voc_2007_train --output_dir=${TF_SSD_Records}
		if [[ $? -eq 0 ]]; then
			DATE_PREFIX "INFO" "TF-Records converted!"	
		else
			DATE_PREFIX "ERROR" "Converting failed!"
			exit -3
		fi
	else
		DATE_PREFIX "INFO" "TF-Records already exists, will not download again!"
	fi
} 

## Start from here

DOWNLOAD_DATA_SET
DOWNLOAD_BASE_MODEL
CLONE_TF
PREPARE_TF_Records
