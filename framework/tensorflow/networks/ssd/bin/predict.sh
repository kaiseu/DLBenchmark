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

LOCAL_CONF_FILE=${CURRENT_DIR}/../conf/localSetting.conf

echo "****************************************************************"
DATE_PREFIX "INFO" "Loading Local Configuration file from: ${LOCAL_CONF_FILE}..."
source "${LOCAL_CONF_FILE}"

if [[ -f "${CAFFE_EXEC}" ]]; then
        DATE_PREFIX "INFO"  "Will use executable file: ${CAFFE_EXEC}"
else
	DATE_PREFIX "ERROR"  "Executable file does not exist, please build intelcaffe first, exiting ..."
	exit -1
fi

if [[ -f "${CAFFE_WEIGHTS_PATH}" ]]; then
	DATE_PREFIX "INFO" "Using Caffe weights file: ${CAFFE_WEIGHTS_PATH}"
else
	DATE_PREFIX "ERROR" "Caffe weights file does not exist, exiting ..."
	exit -2
fi

if [[ -f "${CAFFE_MODEL_PATH}" ]]; then
	DATE_PREFIX "INFO" "Using Caffe model file: ${CAFFE_MODEL_PATH}"
	DATE_PREFIX "INFO" "Applying batch size: ${BATCHSIZE}"
	sed -i "s/batch_size: .*/batch_size: ${BATCHSIZE}/" ${CAFFE_MODEL_PATH}
	DATE_PREFIX "INFO" "Applied!"
else
	DATE_PREFIX "ERROR" "Caffe model file does not exist, exiting ..."
	exit -2
fi

#############################################################################
## Do NOT Change if you do not known what you're doing!
#############################################################################
## Create Local Log Dir
LOCAL_LOG_DIR="${CURRENT_DIR}/../logs"
if [[ ! -d ${LOCAL_LOG_DIR} ]]; then
        mkdir -p ${LOCAL_LOG_DIR}
fi
LOCAL_LOG_FILE=logs_${BASE_MODEL}_${IMAGE_RESOLUTION}x${IMAGE_RESOLUTION}_${DATA_SET}_${ITERATION}.log

DATE_PREFIX "INFO" "Predicting Caffe SSD with ${BASE_MODEL} on ${DATA_SET} with image resolution: ${IMAGE_RESOLUTION}x${IMAGE_RESOLUTION} and batch size: ${BATCHSIZE} for ${ITERATION} iterations(replica: ${DATA_REPLICA}) ..."
DATE_PREFIX "INFO" "${CAFFE_EXEC} test --detection --model ${CAFFE_MODEL_PATH} --weights ${CAFFE_WEIGHTS_PATH} --iterations=${ITERATION}"
cd ${CAFFE_ROOT}
START=$(date +%s.%N)
${CAFFE_EXEC} test --detection --model ${CAFFE_MODEL_PATH} --weights ${CAFFE_WEIGHTS_PATH} --iterations=${ITERATION} 2>&1 | tee -a ${LOCAL_LOG_FILE}
RET=$?
ELAPSED_TIME=$(echo "$(date +%s.%N) - ${START}" | bc)
ThroughPut=`CALC ${BATCHSIZE}*${ITERATION}/${ELAPSED_TIME}`
if [[ ${RET} == 0 ]]; then
	DATE_PREFIX "INFO" "Predict Done!"
	DATE_PREFIX "INFO" "Summary:"
	echo "Framework   Network   Phase   BaseModel   Dataset   DataReplica  BatchSize  Iterations   ThroughPut(image/s)   ElapsedTime(s)"
	echo -e "caffe        SSD      predict  ${BASE_MODEL}     ${DATA_SET}        ${DATA_REPLICA}         ${BATCHSIZE}           ${ITERATION}	     ${ThroughPut}		 ${ELAPSED_TIME}"
else
	 DATE_PREFIX "ERROR" "Predict failed with some error!"
	 exit -3
fi
cd - >> /dev/null 2>&1
