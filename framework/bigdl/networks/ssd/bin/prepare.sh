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
INT_PASCAL_SERVER="bdpa-gateway.sh.intel.com:8088/dlbenchmark/dataset/PASCAL/"
INT_COCO_SERVER="bdpa-gateway.sh.intel.com:8088/dlbenchmark/dataset/COCO/"
INT_BASE_MODEL_SERVER="bdpa-gateway.sh.intel.com:8088/dlbenchmark/models/ssd2/"
EXT_PASCAL_SERVER="http://host.robots.ox.ac.uk/pascal/VOC/"
EXT_COCO_SERVER="http://images.cocodataset.org/zips/"
EXT_VGG_BASE_MODEL_300="https://doc-0o-30-docs.googleusercontent.com/docs/securesc/ha0ro937gcuc7l7deffksulhg5h7mbp1/4vekjv3i84tfbagshmm8fhibbemagvbk/1515369600000/09260862254863227534/*/0BzKzrI_SkD1_WVVTSmQxU0dVRzA?e=download"
EXT_VGG_BASE_MODEL_512="https://doc-0s-30-docs.googleusercontent.com/docs/securesc/ha0ro937gcuc7l7deffksulhg5h7mbp1/k0ivavusfo30kuo3un6ee1bjutqu8bnb/1515405600000/09260862254863227534/*/0BzKzrI_SkD1_ZDIxVHBEcUNBb2s?e=download"
EXT_ALEXNET_BASE_MODEL_300="https://storage.googleapis.com/drive-bulk-export-anonymous/20180108T064845Z/4133399871716478688/6e39bd56-ef20-422d-b7a6-ec6eed6ed5a4/1/a9eb60b0-f7f2-41a5-bc3f-a825ae0e6f16?authuser"
PASCAL_DATA_DIR=${TEMP_DATA_DIR}/data/pascal
COCO_DATA_DIR=${TEMP_DATA_DIR}/data/coco

function DOWNLOAD_BASE_MODEL(){
	MODEL_NAME=$1
	RESOLUTION=$2
	DATASET=$3
	TIMEOUT="5"
	if [[ "$#" -ne 3 ]]; then
                echo "Usage: $0 BASE_MODEL_NAME IMAGE_RESOLUTION DATASET"
                exit -6
        fi
	
	if [[ x${MODEL_NAME} == "xvgg16" ]]; then
		if [[ ! -f ${TEMP_DATA_DIR}/models/ssd/VGGNet/${DATASET}/SSD_${RESOLUTION}x${RESOLUTION}/VGG_VOC0712_SSD_${RESOLUTION}x${RESOLUTION}_iter_120000.caffemodel ]] || [[ ! -f ${TEMP_DATA_DIR}/models/ssd/VGGNet/${DATASET}/SSD_${RESOLUTION}x${RESOLUTION}/test.prototxt ]]; then
			## Downlaod from Internal Server
			INT_VGG_BASE_MODEL="${INT_BASE_MODEL_SERVER}/VGGNet/${DATASET}/SSD_${RESOLUTION}x${RESOLUTION}"
			RET_CODE=`curl -L -I -s --connect-timeout ${TIMEOUT} ${INT_VGG_BASE_MODEL} -w %{http_code} | tail -n1`
			if [[ x${RET_CODE} == "x200" ]]; then
				echo "Begin to download base model: ${MODEL_NAME} with resolution: ${RESOLUTION}x${RESOLUTION} from Internal server: ${INT_VGG_BASE_MODEL} ..."
				if [[ ! -d ${TEMP_DATA_DIR}/models/ssd/VGGNet/${DATASET}/SSD_${RESOLUTION}x${RESOLUTION} ]]; then
					mkdir -p ${TEMP_DATA_DIR}/models/ssd/VGGNet/${DATASET}/SSD_${RESOLUTION}x${RESOLUTION}
				fi
				cd ${TEMP_DATA_DIR}/models/ssd/VGGNet/${DATASET}/
				curl -O ${INT_BASE_MODEL_SERVER}/VGGNet/${DATASET}/classname.txt
				cd - >> /dev/null 2>&1
				cd ${TEMP_DATA_DIR}/models/ssd/VGGNet/${DATASET}/SSD_${RESOLUTION}x${RESOLUTION}/
				curl -OO ${INT_BASE_MODEL_SERVER}/VGGNet/${DATASET}/SSD_${RESOLUTION}x${RESOLUTION}/{test.prototxt,VGG_VOC0712_SSD_${RESOLUTION}x${RESOLUTION}_iter_120000.caffemodel}
				cd - >> /dev/null 2>&1
			else
				## Downlaod from External Server, Only support dataset VOC0712
				eval EXT_VGG_BASE_MODEL="\${EXT_VGG_BASE_MODEL_${RESOLUTION}}"
				curl -L -I -s --connect-timeout ${TIMEOUT} ${EXT_VGG_BASE_MODEL} -w %{http_code} | grep "HTTP/1.1 200" >> /dev/null 2>&1
				if [[ $? ]]; then
					echo "Begin to download base model: ${MODEL_NAME} with resolution: ${RESOLUTION}x${RESOLUTION} from External server: ${EXT_VGG_BASE_MODEL} ..."
					if [[ ! -d ${TEMP_DATA_DIR}/models/ssd/ ]]; then
						mkdir -p ${TEMP_DATA_DIR}/models/ssd/
					fi
					wget ${EXT_VGG_BASE_MODEL} -O ${TEMP_DATA_DIR}/models/ssd/models_VGGNet_VOC0712_SSD_${RESOLUTION}x${RESOLUTION}.tar.gz
					tar xvf ${TEMP_DATA_DIR}/models/ssd/models_VGGNet_VOC0712_SSD_${RESOLUTION}x${RESOLUTION}.tar.gz -C ${TEMP_DATA_DIR}/models/ssd/ >> /dev/null 2>&1
					mv ${TEMP_DATA_DIR}/models/ssd/models/VGGNet/ ${TEMP_DATA_DIR}/models/ssd/
					rm -fr ${TEMP_DATA_DIR}/models/ssd/models/
				else
					echo "Can not connect to Server: ${EXT_VGG_BASE_MODEL}, download base model: ${MODEL_NAME} with resolution: ${RESOLUTION}x${RESOLUTION} failed! Please check and try again. Exiting..."
					exit -7
				fi
			fi
			echo "Download Done!"
			echo "Base model have been saved to: ${TEMP_DATA_DIR}/models/ssd/VGGNet/VOC0712/SSD_${RESOLUTION}x${RESOLUTION}"
		else
			echo "Base model: ${MODEL_NAME} already exists in ${TEMP_DATA_DIR}/models/ssd/VGGNet/VOC0712/SSD_${RESOLUTION}x${RESOLUTION}, will not download again!"
		fi
	elif [[ x${MODEL_NAME} == "xalexnet" ]]; then
		if [[ ! -f ${TEMP_DATA_DIR}/models/ssd/AlexNet/${DATASET}/SSD_${RESOLUTION}x${RESOLUTION}/ALEXNET_JDLOGO_V4_SSD_${RESOLUTION}x${RESOLUTION}_iter_920.caffemodel ]] || [[ ! -f ${TEMP_DATA_DIR}/models/ssd/AlexNet/${DATASET}/SSD_${RESOLUTION}x${RESOLUTION}/deploy.prototxt ]] || [[ ! -f ${TEMP_DATA_DIR}/models/ssd/AlexNet/${DATASET}/SSD_${RESOLUTION}x${RESOLUTION}/classname.txt ]]; then
			if [[ ! x${RESOLUTION} == "x300" ]]; then
                                        echo "Only support ${MODEL_NAME} with resolution: 300x300 currently! Exiting..."
                                        exit -8
                        fi
			## Downlaod from Internal Server
			INT_ALEX_BASE_MODEL=${INT_BASE_MODEL_SERVER}/AlexNet/${DATASET}/SSD_${RESOLUTION}x${RESOLUTION}
			RET_CODE=`curl -L -I -s --connect-timeout ${TIMEOUT} ${INT_ALEX_BASE_MODEL} -w %{http_code} | tail -n1`
			if [[ x${RET_CODE} == "x200" ]]; then
				echo "Begin to download base model: ${MODEL_NAME} with resolution: ${RESOLUTION}x${RESOLUTION} from Internal server: ${INT_ALEX_BASE_MODEL} ..."
				ALEX_BASE_MODEL_DIR=${TEMP_DATA_DIR}/models/ssd/AlexNet/${DATASET}/SSD_${RESOLUTION}x${RESOLUTION}
				if [[ ! -d ${ALEX_BASE_MODEL_DIR} ]]; then
					mkdir -p ${ALEX_BASE_MODEL_DIR}
				fi
				cd ${ALEX_BASE_MODEL_DIR}
				curl -OOO ${INT_ALEX_BASE_MODEL}/{ALEXNET_JDLOGO_V4_SSD_300x300_iter_920.caffemodel,deploy.prototxt,classname.txt}
				cd - >> /dev/null 2>&1
			else
				## Downlaod from External Server
				eval EXT_ALEXNET_BASE_MODEL="\${EXT_ALEXNET_BASE_MODEL_${RESOLUTION}}"
				echo ${EXT_ALEXNET_BASE_MODEL}
				echo "curl -L -I -s --connect-timeout ${TIMEOUT} ${EXT_ALEXNET_BASE_MODEL} -w %{http_code} | grep "HTTP/1.1 200" >> /dev/null 2>&1"
				curl -L -I -s --connect-timeout ${TIMEOUT} ${EXT_ALEXNET_BASE_MODEL} -w %{http_code} | grep "HTTP/1.1 200" >> /dev/null 2>&1
				if [[ $? ]]; then
					echo "Begin to download base model: ${MODEL_NAME} with resolution: ${RESOLUTION}x${RESOLUTION} from External server: ${EXT_ALEXNET_BASE_MODEL} ..."
					if [[ ! -d ${TEMP_DATA_DIR}/models/ssd/AlexNet/${DATASET}/SSD_${RESOLUTION}x${RESOLUTION} ]]; then
						mkdir -p ${TEMP_DATA_DIR}/models/ssd/AlexNet/${DATASET}/SSD_${RESOLUTION}x${RESOLUTION}
					fi
					wget ${EXT_ALEXNET_BASE_MODEL} -O ${TEMP_DATA_DIR}/models/ssd/AlexNet/${DATASET}/SSD_${RESOLUTION}x${RESOLUTION}/models_ALEXNet_${DATASET}_SSD_${RESOLUTION}x${RESOLUTION}.zip
					cd ${TEMP_DATA_DIR}/models/ssd/AlexNet/${DATASET}/SSD_${RESOLUTION}x${RESOLUTION}
					unzip models_ALEXNet_${DATASET}_SSD_${RESOLUTION}x${RESOLUTION}.zip >> /dev/null 2>&1
					mv ./ssd_alexnet/* ./
					rm -fr ./ssd_alexnet/
				else
					echo "Can not connect to Server: ${EXT_ALEXNET_BASE_MODEL}, download base model: ${MODEL_NAME} with resolution: ${RESOLUTION}x${RESOLUTION} failed! Please check and try again. Exiting..."
					exit -9
				fi
			fi
			echo "Download Done!"
			echo "Base model have been saved to: ${TEMP_DATA_DIR}/models/ssd/AlexNet/${DATASET}/SSD_${RESOLUTION}x${RESOLUTION}"
		else
			echo ""Base model: ${MODEL_NAME} already exists in ${TEMP_DATA_DIR}/models/ssd/AlexNet/${DATASET}/SSD_${RESOLUTION}x${RESOLUTION}, will not download again!""
				
		fi			
	else
		echo "Base model only support vgg16 or alexnet currently, exiting..."
		exit 10
	fi
}

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
                cd - >> /dev/null 2>&1
                echo "Extract Done!"
                echo "==============================================================================================="
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
		echo "Usage: $0 DIRECTORY"
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

function DOWNLOAD_DATASET(){
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
}

DOWNLOAD_BASE_MODEL vgg16 512  VOC0712
