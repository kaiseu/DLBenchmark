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

if [[ -f "${TF_SSD_EXEC}" ]]; then
        DATE_PREFIX "INFO"  "Will use executable file: ${TF_SSD_EXEC}"
else
	DATE_PREFIX "ERROR"  "Executable file: ${TF_SSD_EXEC} does not exist, exiting ..."
	exit -1
fi

if [[ -d "${TF_SSD_Records}" ]]; then
	DATE_PREFIX "INFO" "Using dataset TF-Records from: ${TF_SSD_Records}"
else
	DATE_PREFIX "ERROR" "Dataset TF-Records: ${TF_SSD_Records} does not exist, exiting ..."
	exit -2
fi

if [[ -f "${TF_CHECKPOINT_PATH}.index" ]]; then
	DATE_PREFIX "INFO" "Using Tensorflow Checkpoint file: ${TF_CHECKPOINT_PATH}"\
	DATE_PREFIX "INFO" "Model name is: ${MODEL_NMAE}"
	DATE_PREFIX "INFO" "Dataset name is: ${DATASET_NAME}"
	DATE_PREFIX "INFO" "Batch size is: ${BATCHSIZE}"
	DATE_PREFIX "INFO" "Result dir is: ${EVAL_DIR}"
else
	DATE_PREFIX "ERROR" "Tensorflow checkpoint file: ${TF_CHECKPOINT_PATH} does not exist, exiting ..."
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
LOCAL_LOG_FILE=logs_${BASE_MODEL}_${IMAGE_RESOLUTION}x${IMAGE_RESOLUTION}_${DATA_SET}_bs${ITERATION}.log

DATE_PREFIX "INFO" "Predicting Tensorflow SSD with ${BASE_MODEL} on ${DATA_SET} with image resolution: ${IMAGE_RESOLUTION}x${IMAGE_RESOLUTION} and batch size: ${BATCHSIZE} for replica: ${DATA_REPLICA} ..."
COMMAND="${TF_SSD_EXEC} --eval_dir=${EVAL_DIR} --dataset_dir=${TF_SSD_Records} --dataset_name=${DATASET_NAME} --model_name=${MODEL_NMAE} --checkpoint_path=${TF_CHECKPOINT_PATH} --batch_size=${BATCHSIZE}"
DATE_PREFIX "INFO" "python ${COMMAND}"
cd ${TF_SSD_ROOT}
START=$(date +%s.%N)
python ${COMMAND} 2>&1 | tee -a ${LOCAL_LOG_FILE}
RET=$?
ELAPSED_TIME=$(echo "$(date +%s.%N) - ${START}" | bc)
#ThroughPut=`CALC ${BATCHSIZE}*${ITERATION}/${ELAPSED_TIME}`
if [[ ${RET} == 0 ]]; then
	DATE_PREFIX "INFO" "Predict Done!"
	DATE_PREFIX "INFO" "Summary:"
	echo "Framework   Network   Phase   BaseModel   Dataset   DataReplica  BatchSize  Iterations   ThroughPut(image/s)   ElapsedTime(s)"
	echo -e "tensorflow        SSD      predict  ${BASE_MODEL}     ${DATA_SET}        ${DATA_REPLICA}         ${BATCHSIZE}           ${ITERATION}	     ${ThroughPut}		 ${ELAPSED_TIME}"
else
	 DATE_PREFIX "ERROR" "Predict failed with some error!"
	 exit -3
fi
cd - >> /dev/null 2>&1
