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
if [[ ${BASE_MODEL} == "vgg16" ]]; then
	CLASSNAME=${SSD_MODEL_HOME}/VGGNet/${DATA_SET}/classname.txt
	CAFFEDEF=${SSD_MODEL_HOME}/VGGNet/${DATA_SET}/SSD_${IMAGE_RESOLUTION}x${IMAGE_RESOLUTION}/test.prototxt
	CAFFEMODEL=${SSD_MODEL_HOME}/VGGNet/${DATA_SET}/SSD_${IMAGE_RESOLUTION}x${IMAGE_RESOLUTION}/VGG_VOC0712_SSD_${IMAGE_RESOLUTION}x${IMAGE_RESOLUTION}_iter_120000.caffemodel
	DATE_PREFIX "INFO"  "SSD_MODEL_HOME is: ${SSD_MODEL_HOME}/VGGNet/${DATA_SET}/"
elif [[ ${BASE_MODEL} == "alexnet" ]]; then
	CLASSNAME=${SSD_MODEL_HOME}/AlexNet/classname.txt
	CAFFEDEF=${SSD_MODEL_HOME}/AlexNet/deploy.prototxt
	CAFFEMODEL=${SSD_MODEL_HOME}/AlexNet/ALEXNET_JDLOGO_V4_SSD_${IMAGE_RESOLUTION}x${IMAGE_RESOLUTION}_iter_920.caffemodel
	DATE_PREFIX "INFO"  "SSD_MODEL_HOME is: ${SSD_MODEL_HOME}/AlexNet/"
fi

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
DATE_PREFIX "INFO"  "BASE_MODEL is: ${BASE_MODEL}"
DATE_PREFIX "INFO"  "DATA_SET is: ${DATA_SET}"

echo "****************************************************************"
date > ${LOCAL_LOG_DIR}/${LOCAL_LOG_FILE}
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
  --caffeDefPath  ${CAFFEDEF} \
  --caffeModelPath  ${CAFFEMODEL} \
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
  --caffeDefPath  ${CAFFEDEF} \
  --caffeModelPath  ${CAFFEMODEL} \
  --classname ${CLASSNAME} \
  -b ${BATCHSIZE} \
  -r ${IMAGE_RESOLUTION} \
  -p ${NUM_PARTITION} \
  -q ${IS_QUANT_ENABLE} | tee -a ${LOCAL_LOG_DIR}/${LOCAL_LOG_FILE}
