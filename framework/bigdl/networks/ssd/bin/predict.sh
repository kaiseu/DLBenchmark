#! /bin/bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
JAR="${CURRENT_DIR}/../jars/pipeline-0.1-SNAPSHOT-jar-with-dependencies.jar"

if [[ -f "${JAR}" ]]; then
	echo "Will use executable jar file: ${JAR}" 
else
	echo "Executable jar file does not exist, you may need to build the project first! Exiting..."
	exit -1	
fi

CLASS=com.intel.analytics.zoo.pipeline.ssd.example.Predict

LOCAL_CONF_FILE=${CURRENT_DIR}/../conf/localSetting.conf

echo "==============================================================================================="
echo "Loading Local Configuration file from: ${LOCAL_CONF_FILE}..."
source "${LOCAL_CONF_FILE}"

#############################################################################
## Do NOT Change if you do not known what you're doing!
#############################################################################
## Create Local Log Dir
LOCAL_LOG_DIR="${CURRENT_DIR}/../logs"
if [[ ! -d ${LOCAL_LOG_DIR} ]]; then
        mkdir -p ${LOCAL_LOG_DIR}
fi
LOCAL_LOG_FILE=logs_${BASE_MODEL}_${IMAGE_RESOLUTION}x${IMAGE_RESOLUTION}_${DATA_SET}_${IS_QUANT_ENABLE}.log


MODEL_HOME="${CURRENT_DIR}/../models"
echo "MODEL_HOME is: ${MODEL_HOME}"

## Which Base Model to use?
if [[ ${BASE_MODEL} == "vgg16" ]]; then
	CLASSNAME=${MODEL_HOME}/VGGNet/VOC0712/classname.txt
	CAFFEDEF=${MODEL_HOME}/VGGNet/VOC0712/SSD_${IMAGE_RESOLUTION}x${IMAGE_RESOLUTION}/test.prototxt
	CAFFEMODEL=${MODEL_HOME}/VGGNet/VOC0712/SSD_${IMAGE_RESOLUTION}x${IMAGE_RESOLUTION}/VGG_VOC0712_SSD_${IMAGE_RESOLUTION}x${IMAGE_RESOLUTION}_iter_120000.caffemodel
elif [[ ${BASE_MODEL} == "alexnet" ]]; then
	CLASSNAME=${MODEL_HOME}/AlexNet/classname.txt
	CAFFEDEF=${MODEL_HOME}/AlexNet/deploy.prototxt
	CAFFEMODEL=${MODEL_HOME}/AlexNet/ALEXNET_JDLOGO_V4_SSD_${IMAGE_RESOLUTION}x${IMAGE_RESOLUTION}_iter_920.caffemodel
fi

if [[ ${DATA_SET} == "coco" ]]; then
        SEQ_DATA_DIR=${TEMP_DATA_DIR}/coco-minival
elif [[ ${DATA_SET} == "voc" ]]; then
	SEQ_DATA_DIR=${TEMP_DATA_DIR}/voc-all
fi

echo "BASE_MODEL is: ${BASE_MODEL}"
echo "DATA_SET is: ${DATA_SET}"

echo "==============================================================================================="
date > ${LOCAL_LOG_DIR}/${LOCAL_LOG_FILE}
echo "
spark-submit \
  --master ${SPARK_MASTER} \
  --executor-cores ${EXECUTOR_CORES} \
  --num-executors ${NUM_EXECUTORS} \
  --total-executor-cores ${TOTAL_CORES} \
  --driver-memory ${DRIVER_MEMORY} \
  --executor-memory ${EXECUTOR_MEMORY} \
  --class ${CLASS} \
  ${JAR} \
  -f ${SEQ_DATA_DIR} \
  --folderType ${FOLDER_TYPE} \
  -o ${TEMP_OUTPUT_DIR} \
  --caffeDefPath  ${CAFFEDEF} \
  --caffeModelPath  ${CAFFEMODEL} \
  -t ${BASE_MODEL} \
  --classname ${CLASSNAME} \
  -v false \
  -b ${BATCHSIZE} \
  -r ${IMAGE_RESOLUTION} \
  -s false \
  -p ${NUM_PARTITION} \
  -q ${IS_QUANT_ENABLE}
" | tee -a ${LOCAL_LOG_DIR}/${LOCAL_LOG_FILE}

echo "==============================================================================================="

time spark-submit \
  --master ${SPARK_MASTER} \
  --executor-cores ${EXECUTOR_CORES} \
  --num-executors ${NUM_EXECUTORS} \
  --total-executor-cores ${TOTAL_CORES} \
  --driver-memory ${DRIVER_MEMORY} \
  --executor-memory ${EXECUTOR_MEMORY} \
  --class ${CLASS} \
  ${JAR} \
  -f ${SEQ_DATA_DIR} \
  --folderType ${FOLDER_TYPE} \
  -o ${TEMP_OUTPUT_DIR} \
  --caffeDefPath  ${CAFFEDEF} \
  --caffeModelPath  ${CAFFEMODEL} \
  -t ${BASE_MODEL} \
  --classname ${CLASSNAME} \
  -v false \
  -b ${BATCHSIZE} \
  -r ${IMAGE_RESOLUTION} \
  -s false \
  -p ${NUM_PARTITION} \
  -q ${IS_QUANT_ENABLE} | tee -a ${LOCAL_LOG_DIR}/${LOCAL_LOG_FILE}

