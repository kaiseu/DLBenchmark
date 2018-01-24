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

## DO Not Editi, If You NOT Know What You are doing!
INT_PASCAL_SERVER="bdpa-gateway.sh.intel.com:8088/dlbenchmark/dataset/PASCAL/"
INT_COCO_SERVER="bdpa-gateway.sh.intel.com:8088/dlbenchmark/dataset/COCO/"
INT_BASE_MODEL_SERVER="bdpa-gateway.sh.intel.com:8088/dlbenchmark/models/ssd"
INT_BASE_MODEL_SERVER_CAFFE=${INT_BASE_MODEL_SERVER}/base_model/caffe
INT_BASE_MODEL_SERVER_BIGDL=${INT_BASE_MODEL_SERVER}/base_model/bigdl
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

## Download BigDL base model
function DOWNLOAD_BIGDL_MODEL(){
	Usage="Usage: DOWNLOAD_BIGDL_MODEL [-N <Network>] [-R <300|512>] [-Q <true|false>] [-D <COCO|PASCAL>]"
	while getopts ":N:R:Q:D:" opt; do
		case "${opt}" in
		N)
			NETWORK=${OPTARG}
			;;
		R)
			RESOLUTION=${OPTARG}
			;;
		Q)
			QUANTIZE=${OPTARG}
			;;
		D)
			DATASET=${OPTARG}
			;;
		*)
			echo ${Usage}
			;;
		esac
	done
	shift $(( OPTIND-1))
	if [[ ${QUANTIZE} == "true" ]]; then
		QUANTIZE="-quantize"
	else
		QUANTIZE=""
	fi

	if [[ ${DATASET} == "VOC0712" ]]; then
		DATASET="PASCAL"
	fi
       
	local MODEL_NAME="bigdl_ssd-${NETWORK}-${RESOLUTION}x${RESOLUTION}${QUANTIZE}_${DATASET}_${BigDL_VERSION}.model"
	local MODEL_PATH=${INT_BASE_MODEL_SERVER_BIGDL}/${MODEL_NAME}
	
	echo "****************************************************************"
	if [[ -f ${TEMP_SSD_MODEL_DIR}/bigdl/${MODEL_NAME} ]]; then
		DATE_PREFIX "INFO" "Base model: ${MODEL_NAME} already exists in ${TEMP_SSD_MODEL_DIR}/bigdl, will not download again!"
	else	
		DATE_PREFIX "INFO" "Testing the Network connection to: ${MODEL_PATH} ..."
		local RET_CODE=`curl -L -I -s --connect-timeout ${TIMEOUT} ${MODEL_PATH} -w %{http_code} | tail -n1`
		if [[ x${RET_CODE} == "x200" ]]; then
			DATE_PREFIX "INFO" "Network connection is OK!"
			DATE_PREFIX "INFO" "Begin to download base model: ${MODEL_NAME} from Internal server: ${INT_BASE_MODEL_SERVER_BIGDL} ..."
			if [[ ! -d ${TEMP_SSD_MODEL_DIR}/bigdl ]]; then
				mkdir -p  ${TEMP_SSD_MODEL_DIR}/bigdl
			fi
			cd ${TEMP_SSD_MODEL_DIR}/bigdl
			curl -O ${MODEL_PATH}
			cd - >> /dev/null 2>&1
			DATE_PREFIX "INFO" "Download Done!"
			DATE_PREFIX "INFO" "Base model have been saved to: ${TEMP_SSD_MODEL_DIR}/bigdl"
		else
			DATE_PREFIX "INFO" "Network connection failed." 
			local MODEL_PATH=${EXT_BASE_MODEL_SERVER_BIGDL}/${MODEL_NAME}	
			DATE_PREFIX "INFO" "Testing the Network connection to: ${MODEL_PATH} ..."
			local RET_CODE=`curl -L -I -s --connect-timeout ${TIMEOUT} ${MODEL_PATH} -w %{http_code} | tail -n1`
			if [[ x${RET_CODE} == "x200" ]]; then
				DATE_PREFIX "INFO" "Network connection is OK!"
				DATE_PREFIX "INFO" "Begin to download base model: ${MODEL_NAME} from external server: ${EXT_BASE_MODEL_SERVER_BIGDL} ..."
				cd ${TEMP_SSD_MODEL_DIR}/bigdl
				curl -O ${MODEL_PATH}
				cd - >> /dev/null 2>&1
				DATE_PREFIX "INFO" "Download Done!"
				DATE_PREFIX "INFO" "Base model have been saved to: ${TEMP_SSD_MODEL_DIR}/bigdl"
			else
				DATE_PREFIX "ERROR" "Download base model: ${MODEL_NAME} failed, possibly because of the network issue"
				exit -13
			fi
		fi
	fi
	## Create the classname.txt file based on dataset
	local CLASS_NAME=${TEMP_SSD_MODEL_DIR}/bigdl/${DATA_SET}_classname.txt
	if [[ ! -f ${CLASS_NAME} ]]; then
		if [[ ${DATA_SET} == "VOC0712" ]]; then
			cp -r ${CURRENT_DIR}/../data/pascal/classname.txt ${CLASS_NAME}
		elif [[ ${DATA_SET} == "COCO" ]]; then
			echo -e "1\n2" > ${CLASS_NAME}
		fi
	fi
}


## Downlaod Caffe Base Models Based on Local Configurations
function DOWNLOAD_CAFFE_MODEL(){
	local RESOLUTION=${IMAGE_RESOLUTION}
	local NETWORK=`echo ${BASE_MODEL} | awk -F "-" '{ print $2 }'`
	if [[ x${NETWORK} == "xvgg16" ]]; then
		if [[ ! -f ${TEMP_SSD_MODEL_DIR}/caffe/VGGNet/${DATA_SET}/SSD_${RESOLUTION}x${RESOLUTION}/VGG_VOC0712_SSD_${RESOLUTION}x${RESOLUTION}_iter_120000.caffemodel ]] || [[ ! -f ${TEMP_SSD_MODEL_DIR}/caffe/VGGNet/${DATA_SET}/SSD_${RESOLUTION}x${RESOLUTION}/test.prototxt ]]; then
			## Downlaod from Internal Server
			local INT_VGG_BASE_MODEL="${INT_BASE_MODEL_SERVER_CAFFE}/VGGNet/${DATA_SET}/SSD_${RESOLUTION}x${RESOLUTION}"
			echo "****************************************************************"
			DATE_PREFIX "INFO" "Testing the Network connection to: ${INT_VGG_BASE_MODEL} ..."
			local RET_CODE=`curl -L -I -s --connect-timeout ${TIMEOUT} ${INT_VGG_BASE_MODEL} -w %{http_code} | tail -n1`
			if [[ x${RET_CODE} == "x200" ]]; then
				DATE_PREFIX "INFO" "Network connection is OK!"	
				DATE_PREFIX "INFO" "Begin to download base model: ${BASE_MODEL} with resolution: ${RESOLUTION}x${RESOLUTION} from Internal server: ${INT_VGG_BASE_MODEL} ..."
				if [[ ! -d ${TEMP_SSD_MODEL_DIR}/caffe/VGGNet/${DATA_SET}/SSD_${RESOLUTION}x${RESOLUTION} ]]; then
					mkdir -p ${TEMP_SSD_MODEL_DIR}/caffe/VGGNet/${DATA_SET}/SSD_${RESOLUTION}x${RESOLUTION}
				fi
				cd ${TEMP_SSD_MODEL_DIR}/caffe/VGGNet/${DATA_SET}/
				curl -O ${INT_BASE_MODEL_SERVER_CAFFE}/VGGNet/${DATA_SET}/classname.txt
				cd - >> /dev/null 2>&1
				cd ${TEMP_SSD_MODEL_DIR}/caffe/VGGNet/${DATA_SET}/SSD_${RESOLUTION}x${RESOLUTION}/
				curl -OO ${INT_BASE_MODEL_SERVER_CAFFE}/VGGNet/${DATA_SET}/SSD_${RESOLUTION}x${RESOLUTION}/{test.prototxt,VGG_VOC0712_SSD_${RESOLUTION}x${RESOLUTION}_iter_120000.caffemodel}
				cd - >> /dev/null 2>&1
				DATE_PREFIX "INFO" "Download Done!"
				DATE_PREFIX "INFO" "Base model have been saved to: ${TEMP_SSD_MODEL_DIR}/caffe/VGGNet/${DATA_SET}/SSD_${RESOLUTION}x${RESOLUTION}"
			else
				DATE_PREFIX "INFO" "Network connection failed."
				## Downlaod from External Server, Only support dataset VOC0712
				eval EXT_VGG_BASE_MODEL="\${EXT_VGG_BASE_MODEL_${RESOLUTION}}"
				DATE_PREFIX "INFO" "Testing the Network connection to: ${EXT_VGG_BASE_MODEL} ..."
				curl -L -I -s --connect-timeout ${TIMEOUT} ${EXT_VGG_BASE_MODEL} -w %{http_code} | grep "HTTP/1.1 200" >> /dev/null 2>&1
				if [[ $? ]]; then
					DATE_PREFIX "INFO" "Network connection is OK!"
					DATE_PREFIX "INFO" "Begin to download base model: ${BASE_MODEL} with resolution: ${RESOLUTION}x${RESOLUTION} from External server: ${EXT_VGG_BASE_MODEL} ..."
					if [[ ! -d ${TEMP_SSD_MODEL_DIR}/caffe ]]; then
						mkdir -p ${TEMP_SSD_MODEL_DIR}/caffe
					fi
					wget ${EXT_VGG_BASE_MODEL} -O ${TEMP_SSD_MODEL_DIR}/caffe/models_VGGNet_VOC0712_SSD_${RESOLUTION}x${RESOLUTION}.tar.gz
					if [[ $? == 0 ]]; then
						tar xvf ${TEMP_SSD_MODEL_DIR}/caffe/models_VGGNet_VOC0712_SSD_${RESOLUTION}x${RESOLUTION}.tar.gz -C ${TEMP_SSD_MODEL_DIR}/caffe >> /dev/null 2>&1
						mv ${TEMP_SSD_MODEL_DIR}/caffe/models/VGGNet/ ${TEMP_SSD_MODEL_DIR}/caffe
						rm -fr ${TEMP_SSD_MODEL_DIR}/caffe/models/
						DATE_PREFIX "INFO" "Download Done!"
						DATE_PREFIX "INFO" "Base model have been saved to: ${TEMP_SSD_MODEL_DIR}/caffe/VGGNet/VOC0712/SSD_${RESOLUTION}x${RESOLUTION}"
					else
						DATE_PREFIX "ERROR" "Download base model: ${BASE_MODEL} failed, possibly because of the network issue"
						exit -10
					fi
				else
					DATE_PREFIX "INFO" "Can not connect to Server: ${EXT_VGG_BASE_MODEL}, download base model: ${BASE_MODEL} with resolution: ${RESOLUTION}x${RESOLUTION} failed! Please check and try again. Exiting..."
					exit -7
				fi
			fi
		else
			DATE_PREFIX "INFO" "Base model: ${BASE_MODEL} already exists in ${TEMP_SSD_MODEL_DIR}/caffe/VGGNet/${DATA_SET}/SSD_${RESOLUTION}x${RESOLUTION}, will not download again!"
		fi
	elif [[ x${NETWORK} == "xalexnet" ]]; then
		if [[ ! -f ${TEMP_SSD_MODEL_DIR}/caffe/AlexNet/${DATA_SET}/SSD_${RESOLUTION}x${RESOLUTION}/ALEXNET_JDLOGO_V4_SSD_${RESOLUTION}x${RESOLUTION}_iter_920.caffemodel ]] || [[ ! -f ${TEMP_SSD_MODEL_DIR}/caffe/AlexNet/${DATA_SET}/SSD_${RESOLUTION}x${RESOLUTION}/deploy.prototxt ]] || [[ ! -f ${TEMP_SSD_MODEL_DIR}/caffe/AlexNet/${DATA_SET}/SSD_${RESOLUTION}x${RESOLUTION}/classname.txt ]]; then
			if [[ ! x${RESOLUTION} == "x300" ]]; then
                                        DATE_PREFIX "INFO" "Only support ${BASE_MODEL} with resolution: 300x300 currently! Exiting..."
                                        exit -8
                        fi
			## Downlaod from Internal Server
			local INT_ALEX_BASE_MODEL=${INT_BASE_MODEL_SERVER_CAFFE}/AlexNet/${DATA_SET}/SSD_${RESOLUTION}x${RESOLUTION}
			echo "****************************************************************"
			DATE_PREFIX "INFO" "Testing the Network connection to: ${INT_ALEX_BASE_MODEL} ..."	
			echo "curl -L -I -s --connect-timeout ${TIMEOUT} ${INT_ALEX_BASE_MODEL} -w %{http_code} | tail -n1"
			local RET_CODE=`curl -L -I -s --connect-timeout ${TIMEOUT} ${INT_ALEX_BASE_MODEL} -w %{http_code} | tail -n1`
			if [[ x${RET_CODE} == "x200" ]]; then
				DATE_PREFIX "INFO" "Network connection is OK!"	
				DATE_PREFIX "INFO" "Begin to download base model: ${BASE_MODEL} with resolution: ${RESOLUTION}x${RESOLUTION} from Internal server: ${INT_ALEX_BASE_MODEL} ..."
				ALEX_BASE_MODEL_DIR=${TEMP_SSD_MODEL_DIR}/caffe/AlexNet/${DATA_SET}/SSD_${RESOLUTION}x${RESOLUTION}
				if [[ ! -d ${ALEX_BASE_MODEL_DIR} ]]; then
					mkdir -p ${ALEX_BASE_MODEL_DIR}
				fi
				cd ${ALEX_BASE_MODEL_DIR}
				curl -OOO ${INT_ALEX_BASE_MODEL}/{ALEXNET_JDLOGO_V4_SSD_300x300_iter_920.caffemodel,deploy.prototxt,classname.txt}
				cd - >> /dev/null 2>&1
				DATE_PREFIX "INFO" "Download Done!"
				DATE_PREFIX "INFO" "Base model have been saved to: ${TEMP_SSD_MODEL_DIR}/caffe/AlexNet/${DATA_SET}/SSD_${RESOLUTION}x${RESOLUTION}"
			else
				DATE_PREFIX "INFO" "Network connection failed."	
				## Downlaod from External Server
				eval EXT_ALEXNET_BASE_MODEL="\${EXT_ALEXNET_BASE_MODEL_${RESOLUTION}}"
				DATE_PREFIX "INFO" "Testing the Network connection to: ${EXT_ALEXNET_BASE_MODEL} ..."
				curl -L -I -s --connect-timeout ${TIMEOUT} ${EXT_ALEXNET_BASE_MODEL} -w %{http_code} | grep "HTTP/1.1 200" >> /dev/null 2>&1
				if [[ $? ]]; then
					DATE_PREFIX "INFO" "Network connection is OK!"
					DATE_PREFIX "INFO" "Begin to download base model: ${BASE_MODEL} with resolution: ${RESOLUTION}x${RESOLUTION} from External server: ${EXT_ALEXNET_BASE_MODEL} ..."
					if [[ ! -d ${TEMP_SSD_MODEL_DIR}/caffe/AlexNet/${DATA_SET}/SSD_${RESOLUTION}x${RESOLUTION} ]]; then
						mkdir -p ${TEMP_SSD_MODEL_DIR}/caffe/AlexNet/${DATA_SET}/SSD_${RESOLUTION}x${RESOLUTION}
					fi
					wget ${EXT_ALEXNET_BASE_MODEL} -O ${TEMP_SSD_MODEL_DIR}/caffe/AlexNet/${DATA_SET}/SSD_${RESOLUTION}x${RESOLUTION}/models_ALEXNet_${DATA_SET}_SSD_${RESOLUTION}x${RESOLUTION}.zip
					if [[ $? == 0 ]]; then
						cd ${TEMP_SSD_MODEL_DIR}/caffe/AlexNet/${DATA_SET}/SSD_${RESOLUTION}x${RESOLUTION}
						unzip models_ALEXNet_${DATA_SET}_SSD_${RESOLUTION}x${RESOLUTION}.zip >> /dev/null 2>&1
						mv ./ssd_alexnet/* ./
						rm -fr ./ssd_alexnet/
						cd -
						DATE_PREFIX "INFO" "Download Done!"
		                                DATE_PREFIX "INFO" "Base model have been saved to: ${TEMP_SSD_MODEL_DIR}/caffe/AlexNet/${DATA_SET}/SSD_${RESOLUTION}x${RESOLUTION}"
					else
						DATE_PREFIX "INFO" "Download base model: ${BASE_MODEL} failed, possibly because of the network issue"
						exit 11
					fi	
				else
					DATE_PREFIX "INFO" "Can not connect to Server: ${EXT_ALEXNET_BASE_MODEL}, download base model: ${BASE_MODEL} with resolution: ${RESOLUTION}x${RESOLUTION} failed! Please check and try again. Exiting..."
					exit -9
				fi
			fi
		else
			DATE_PREFIX "INFO" ""Base model: ${BASE_MODEL} already exists in ${TEMP_SSD_MODEL_DIR}/caffe/AlexNet/${DATA_SET}/SSD_${RESOLUTION}x${RESOLUTION}, will not download again!""
				
		fi			
	else
		DATE_PREFIX "INFO" "Base model only support vgg16 or alexnet currently, exiting..."
		exit 10
	fi
}

## Downlaod Base Models Based on Local Configurations
function DOWNLOAD_BASE_MODEL(){
	local ENGINE=`echo ${BASE_MODEL} | awk -F "-" '{ print $1 }'`	
	local NETWORK=`echo ${BASE_MODEL} | awk -F "-" '{ print $2 }'`
	if [[ x${ENGINE} == "xbigdl" ]]; then
		if [[ x${NETWORK} == "xvgg16" ]]; then
			DOWNLOAD_BIGDL_MODEL -N ${NETWORK} -R ${IMAGE_RESOLUTION} -Q ${IS_QUANT_ENABLE} -D ${DATA_SET}	
		else
			DATE_PREFIX "INFO" "BigDL base model only support vgg16 currently, exiting..."
			exit -14
		fi
	elif [[ x${ENGINE} == "xcaffe" ]]; then
		DOWNLOAD_CAFFE_MODEL
	fi
}

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


function CONVERT_SEQ(){
	echo "****************************************************************"
	if [[ ! -f ${SSD_JARS_PATH} ]]; then
		DATE_PREFIX "INFO" "No Local Executable SSD Jars available, will try to download it ..."
		local REMOTE_SSD_JAR="${INT_BASE_MODEL_SERVER}/jars/${SSD_JARS_NAME}"
		DATE_PREFIX "INFO" "Testing the Network connection to: ${REMOTE_SSD_JAR} ..."
		local RET_CODE=`curl -L -I -s --connect-timeout ${TIMEOUT} ${REMOTE_SSD_JAR} -w %{http_code} | tail -n1`
		if [[ x${RET_CODE} == "x200" ]]; then
			DATE_PREFIX "INFO" "Network connection is OK!"	
			DATE_PREFIX "INFO" "Begin to download Executable SSD Jars ..."
			if [[ ! -d ${TEMP_DATA_DIR}/models/ssd/jars ]]; then
				mkdir -p ${TEMP_DATA_DIR}/models/ssd/jars
			fi
			cd ${TEMP_DATA_DIR}/models/ssd/jars
			curl -O ${REMOTE_SSD_JAR}
			cd - >> /dev/null 2>&1
			DATE_PREFIX "INFO" "Download Done!"
			DATE_PREFIX "INFO" "Executable SSD Jars have been saved to: ${SSD_JARS_PATH}"
			echo "****************************************************************"
		else
			DATE_PREFIX "INFO" "Network connection failed. Please build the SSD first."
			
		fi
	fi
	if [[ x${DATA_SET} == "xVOC0712" ]]; then
		DATE_PREFIX "INFO" "Begin to convert ${DATA_SET} test data ..."
		rm -fr ${PASCAL_DATA_DIR}/seq/
		DATE_PREFIX "INFO" "java -cp ${SSD_JARS_PATH} com.intel.analytics.zoo.pipeline.common.dataset.RoiImageSeqGenerator -f ${PASCAL_DATA_DIR}/VOCdevkit -o ${PASCAL_DATA_DIR}/seq/test -i voc_2007_test -p ${TOTAL_CORES}"
		java -cp ${SSD_JARS_PATH} com.intel.analytics.zoo.pipeline.common.dataset.RoiImageSeqGenerator -f ${PASCAL_DATA_DIR}/VOCdevkit -o ${PASCAL_DATA_DIR}/seq/test -i voc_2007_test -p ${TOTAL_CORES} >> /dev/null 2>&1
		if [[ $? == 0 ]]; then
			rm -fr ${PASCAL_DATA_DIR}/seq/test/.*crc
			DATE_PREFIX "INFO" "Convert done."
		else
			DATE_PREFIX "ERROR" "Convert failed!"
			exit -15
		fi
		DATE_PREFIX "INFO" "Begin to convert ${DATA_SET} train data ..."
		DATE_PREFIX "INFO" "java -cp ${SSD_JARS_PATH} com.intel.analytics.zoo.pipeline.common.dataset.RoiImageSeqGenerator -f ${PASCAL_DATA_DIR}/VOCdevkit -o ${PASCAL_DATA_DIR}/seq/train -i voc_2007_trainval -p ${TOTAL_CORES}"
		java -cp ${SSD_JARS_PATH} com.intel.analytics.zoo.pipeline.common.dataset.RoiImageSeqGenerator -f ${PASCAL_DATA_DIR}/VOCdevkit -o ${PASCAL_DATA_DIR}/seq/train -i voc_2007_trainval -p ${TOTAL_CORES} >> /dev/null 2>&1
		if [[ $? == 0 ]]; then
			rm -fr ${PASCAL_DATA_DIR}/seq/train/.*crc
			DATE_PREFIX "INFO" "Convert done."
		else
			DATE_PREFIX "ERROR" "Convert failed!"
			exit -15
		fi

		SEQ_DATASET_REPLICA ${PASCAL_DATA_DIR}/seq ${DATA_REPLICA} 
		COPY_TO_HDFS ${PASCAL_DATA_DIR}/seq ${HDFS_PASCAL_DIR}
       	elif [[ x${DATA_SET} == "xCOCO" ]]; then
		DATE_PREFIX "INFO" "Begin to convert ${DATA_SET} minival data ..."
		rm -fr ${COCO_DATA_DIR}/seq/
		DATE_PREFIX "INFO" "java -cp ${SSD_JARS_PATH} com.intel.analytics.zoo.pipeline.common.dataset.RoiImageSeqGenerator -f ${COCO_DATA_DIR} -o ${COCO_DATA_DIR}/seq/coco-minival -i coco_minival2014 -p ${TOTAL_CORES}"
		java -cp ${SSD_JARS_PATH} com.intel.analytics.zoo.pipeline.common.dataset.RoiImageSeqGenerator -f ${COCO_DATA_DIR} -o ${COCO_DATA_DIR}/seq/coco-minival -i coco_minival2014 -p ${TOTAL_CORES}
		if [[ $? == 0 ]]; then
			rm -fr ${COCO_DATA_DIR}/seq/coco-minival/.*crc
			DATE_PREFIX "INFO" "Convert done."
		else
			DATE_PREFIX "ERROR" "Convert failed!"
			exit -15
		fi
		SEQ_DATASET_REPLICA ${COCO_DATA_DIR}/seq ${DATA_REPLICA}
		COPY_TO_HDFS ${COCO_DATA_DIR}/seq ${HDFS_COCO_DIR}
       	else
               	DATE_PREFIX "INFO" "Dataset only can be VOC0712 or COCO currently! Exiting..."
               	exit -11
       	fi	
}

function COPY_TO_HDFS(){
	local SRC_DIR=$1
	local DEST_HDFS=$2

	if [[ ! -d ${SRC_DIR} ]] || [[ "`ls -A ${SRC_DIR}`" == "" ]]; then
		DATE_PREFIX "INFO" "Source dir: ${SRC_DIR} does not exist or is empty, exiting ..."
		exit -12
	fi

	if [[ x${IS_HDFS} == "xtrue" ]]; then
		DATE_PREFIX "INFO" "Will transfer the source data from LOCAL: ${SRC_DIR} to HDFS: ${DEST_HDFS} ..."
		hdfs dfs -ls ${DEST_HDFS} >> /dev/null  2>&1
		if [[ ! $? == "0" ]]; then ## if dir not exists on HDFS
			DATE_PREFIX "INFO" "Creating HDFS dir: ${DEST_HDFS} ..."
			hdfs dfs -mkdir -p ${DEST_HDFS}
			DATE_PREFIX "INFO" "Create done!"
		fi
		hdfs dfs -rm -r -skipTrash ${DEST_HDFS}/* >> /dev/null  2>&1 ## delete if there's previous files
		DATE_PREFIX "INFO" "Transfering the data ..."
		hdfs dfs -put ${SRC_DIR} ${DEST_HDFS}
		if [[ $? == "0" ]]; then 
			DATE_PREFIX "INFO" "Transfer Done!"
		else
			DATE_PREFIX "INFO" "Transfer finished with some error..."
		fi
	elif [[ x${IS_HDFS} == "xfalse" ]]; then
		DATE_PREFIX "INFO" "Warning: you have chosen to use source data from local disks, so if there're multi nodes in your cluster, you need copy the source data to the same dir of each node first."
		DATE_PREFIX "INFO" "Warning: You may need below command: "
		DATE_PREFIX "INFO" "Warning: pssh -h SLAVES -i mkdir -p ${SRC_DIR}"
		DATE_PREFIX "INFO" "Warning: pscp -h SLAVES -r ${SRC_DIR} ${SRC_DIR}/../"
		exit -13
	else
		DATE_PREFIX "INFO" "IS_HDFS can only be true or false."
		exit -14
	fi
}

## Start from here

DOWNLOAD_DATA_SET
CONVERT_SEQ
DOWNLOAD_BASE_MODEL 
