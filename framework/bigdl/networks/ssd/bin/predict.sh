#! /bin/bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

## Import functions
if test -z ${DLBENCHMARK_FUNCS}; then
	DLBENCHMARK_FUNCS=${CURRENT_DIR}/../../../../../scripts/function.sh
fi
if [[ ! -x ${DLBENCHMARK_FUNCS} ]]; then
	chmod +x ${DLBENCHMARK_FUNCS}
fi
source ${DLBENCHMARK_FUNCS}

CLASS=com.intel.analytics.zoo.pipeline.ssd.example.Predict

LOCAL_CONF_FILE=${CURRENT_DIR}/../conf/localSetting.conf

echo "****************************************************************"
DATE_PREFIX "INFO" "Loading Local Configuration file from: ${LOCAL_CONF_FILE}..."
source "${LOCAL_CONF_FILE}"

if [[ -f "${SSD_JARS_PATH}" ]]; then
        DATE_PREFIX "INFO"  "Will use executable jar file: ${SSD_JARS_PATH}"
else
        DATE_PREFIX "ERROR"  "Executable jar file does not exist, you may need to build the project first! Exiting..."
        exit -1
fi

#############################################################################
## Do NOT Change if you do not known what you're doing!
#############################################################################
## Create Local Log Dir
LOCAL_LOG_DIR="${CURRENT_DIR}/../logs"
if [[ ! -d ${LOCAL_LOG_DIR} ]]; then
        mkdir -p ${LOCAL_LOG_DIR}
fi
LOCAL_LOG_FILE=logs_${BASE_MODEL}_${IMAGE_RESOLUTION}x${IMAGE_RESOLUTION}_${DATA_SET}_${IS_QUANT_ENABLE}.log


## Which Base Model to use?
ENGINE=`echo ${BASE_MODEL} | awk -F "-" '{ print $1 }'`
NETWORK=`echo ${BASE_MODEL} | awk -F "-" '{ print $2 }'`
if [[ ${ENGINE} == "bigdl" ]]; then
	## Match the base model file name
	if [[ ${IS_QUANT_ENABLE} == "true" ]]; then
		QUANTIZE="-quantize"
	else
		QUANTIZE=""
	fi
	if [[ ${DATA_SET} == "VOC0712" ]]; then
		DATASET="PASCAL"
	else
		DATASET="COCO"
	fi
	MODEL_NAME="bigdl_ssd-${NETWORK}-${IMAGE_RESOLUTION}x${IMAGE_RESOLUTION}${QUANTIZE}_${DATASET}_${BigDL_VERSION}.model"
	export BASE_MODEL_PARAS="--model ${SSD_MODEL_HOME}/${ENGINE}/${MODEL_NAME}"
	
	CLASSNAME=${SSD_MODEL_HOME}/${ENGINE}/${DATA_SET}_classname.txt

elif [[ ${ENGINE} == "caffe" ]]; then
	if [[ ${NETWORK} == "vgg16" ]]; then
		CLASSNAME=${SSD_MODEL_HOME}/${ENGINE}/VGGNet/${DATA_SET}/classname.txt
		CAFFEDEF=${SSD_MODEL_HOME}/${ENGINE}/VGGNet/${DATA_SET}/SSD_${IMAGE_RESOLUTION}x${IMAGE_RESOLUTION}/test.prototxt
		CAFFEMODEL=${SSD_MODEL_HOME}/${ENGINE}/VGGNet/${DATA_SET}/SSD_${IMAGE_RESOLUTION}x${IMAGE_RESOLUTION}/VGG_VOC0712_SSD_${IMAGE_RESOLUTION}x${IMAGE_RESOLUTION}_iter_120000.caffemodel
		DATE_PREFIX "INFO"  "Using SSD model from: ${SSD_MODEL_HOME}/${ENGINE}/VGGNet/${DATA_SET}/"
	elif [[ ${NETWORK} == "alexnet" ]]; then
		CLASSNAME=${SSD_MODEL_HOME}/${ENGINE}/AlexNet/${DATA_SET}/SSD_${IMAGE_RESOLUTION}x${IMAGE_RESOLUTION}/classname.txt
		CAFFEDEF=${SSD_MODEL_HOME}/${ENGINE}/AlexNet/${DATA_SET}/SSD_${IMAGE_RESOLUTION}x${IMAGE_RESOLUTION}/deploy.prototxt
		CAFFEMODEL=${SSD_MODEL_HOME}/${ENGINE}/AlexNet/${DATA_SET}/SSD_${IMAGE_RESOLUTION}x${IMAGE_RESOLUTION}/ALEXNET_JDLOGO_V4_SSD_${IMAGE_RESOLUTION}x${IMAGE_RESOLUTION}_iter_920.caffemodel
		DATE_PREFIX "INFO"  "Using SSD model from: ${SSD_MODEL_HOME}/${ENGINE}/AlexNet/${DATA_SET}/SSD_${IMAGE_RESOLUTION}x${IMAGE_RESOLUTION}"
	fi
	export BASE_MODEL_PARAS="--caffeDefPath  ${CAFFEDEF} --caffeModelPath  ${CAFFEMODEL}"
fi
DATE_PREFIX "INFO" "Base Model parameters: ${BASE_MODEL_PARAS}"

if [[ x${IS_HDFS} == "xtrue" ]]; then
	if [[ x${DATA_SET} == "xVOC0712" ]]; then
		SEQ_DATA_DIR=${HDFS_PASCAL_DIR}/seq/test/
	elif [[ x${DATA_SET} == "xCOCO" ]]; then
		SEQ_DATA_DIR=${HDFS_COCO_DIR}/seq/coco-minival
	fi
elif [[ x${IS_HDFS} == "xfalse" ]]; then
	if [[ x${DATA_SET} == "xVOC0712" ]]; then
		SEQ_DATA_DIR=${PASCAL_DATA_DIR}/seq/test/
	elif [[ x${DATA_SET} == "xCOCO" ]]; then
		SEQ_DATA_DIR=${COCO_DATA_DIR}/seq/coco-minival
	fi
fi

DATE_PREFIX "INFO"  "Sequence data dir is: ${SEQ_DATA_DIR}"
DATE_PREFIX "INFO"  "Using base model: ${BASE_MODEL}"
DATE_PREFIX "INFO"  "Using dataset: ${DATA_SET}"

echo "****************************************************************"
DATE_PREFIX "INFO" "
spark-submit \
  --master ${SPARK_MASTER} \
  --executor-cores ${EXECUTOR_CORES} \
  --num-executors ${NUM_EXECUTORS} \
  --total-executor-cores ${TOTAL_CORES} \
  --driver-memory ${DRIVER_MEMORY} \
  --executor-memory ${EXECUTOR_MEMORY} \
  --driver-class-path ${SSD_JARS_PATH} \
  --class ${CLASS} \
  ${SSD_JARS_PATH} \
  -f ${SEQ_DATA_DIR} \
  --folderType ${FOLDER_TYPE} \
  ${BASE_MODEL_PARAS} \
  --classname ${CLASSNAME} \
  -b ${BATCHSIZE} \
  -r ${IMAGE_RESOLUTION} \
  -p ${NUM_PARTITION} \
  -q ${IS_QUANT_ENABLE}
" | tee -a ${LOCAL_LOG_DIR}/${LOCAL_LOG_FILE}

echo "****************************************************************"

time spark-submit \
  --master ${SPARK_MASTER} \
  --executor-cores ${EXECUTOR_CORES} \
  --num-executors ${NUM_EXECUTORS} \
  --total-executor-cores ${TOTAL_CORES} \
  --driver-memory ${DRIVER_MEMORY} \
  --executor-memory ${EXECUTOR_MEMORY} \
  --driver-class-path ${SSD_JARS_PATH} \
  --class ${CLASS} \
  ${SSD_JARS_PATH} \
  -f ${SEQ_DATA_DIR} \
  --folderType ${FOLDER_TYPE} \
  ${BASE_MODEL_PARAS} \
  --classname ${CLASSNAME} \
  -b ${BATCHSIZE} \
  -r ${IMAGE_RESOLUTION} \
  -p ${NUM_PARTITION} \
  -q ${IS_QUANT_ENABLE} | tee -a ${LOCAL_LOG_DIR}/${LOCAL_LOG_FILE}
