#/bin/bash

CURRENT_DIR=$( cd $( dirname ${BASH_SOURCE[0]} ) && pwd )
BENCHMARK_ROOT=${CURRENT_DIR}/..
LOGS_ROOT=${BENCHMARK_ROOT}/logs

## Load User Configurations
function LOAD_USER_CONF(){
	USER_CONF_FILE=${BENCHMARK_ROOT}/conf/userSettings.conf
	if [[ -f ${USER_CONF_FILE} ]]; then
		echo "==============================================================================================="
	        DATE_PREFIX "INFO" "Loading User Configuration file from: ${USER_CONF_FILE} ..."
	        source "${USER_CONF_FILE}"
	        DATE_PREFIX "INFO" "Loading Done!"
		echo -e "===============================================================================================\n"
	else
		DATE_PREFIX "ERROR" "User Configuration file:${USER_CONF_FILE} does not exist, exiting..."
		 exit -1
	fi
}

function RUN_NETWORK(){
	CUR_ENGINE=$1
	CUR_NETWORK=$2
	CUR_PHASE=$3
	
	CUR_ENGINE_ROOT=${BENCHMARK_ROOT}/framework/${CUR_ENGINE}
	CUR_NETWORK_ROOT=${CUR_ENGINE_ROOT}/networks/${CUR_NETWORK}
	LOGS_ENGINE_ROOT=${LOGS_ROOT}/${CUR_ENGINE}
	LOGS_NETWORK_ROOT=${LOGS_ENGINE_ROOT}/logs-${CUR_ENGINE}-${CUR_NETWORK}-`date +%Y%m%d%H%M%S`
	LOGS_PHASE=${LOGS_NETWORK_ROOT}/${CUR_PHASE}.log
	EXEC_SCRIPT=${CUR_NETWORK_ROOT}/bin/${CUR_PHASE}.sh
	if [[ ! -d ${LOGS_NETWORK_ROOT} ]]; then
		mkdir -p ${LOGS_NETWORK_ROOT}
	fi	
	LOAD_USER_CONF >> ${LOGS_PHASE}
	echo "***********************************************************************************************" | tee -a ${LOGS_PHASE}
	DATE_PREFIX "INFO" "${DATE_PREFIX} Current benchmark engine is: ${CUR_ENGINE}, engine root dir is: ${CUR_ENGINE_ROOT}." | tee -a ${LOGS_PHASE}
	DATE_PREFIX "INFO" "Current network to run is: ${CUR_NETWORK}, network root dir is: ${CUR_NETWORK_ROOT}." | tee -a ${LOGS_PHASE}
	DATE_PREFIX "INFO" "Current phase to run is: ${CUR_PHASE}, calling script: ${EXEC_SCRIPT} ..." | tee -a ${LOGS_PHASE}
	sh ${EXEC_SCRIPT} | tee -a ${LOGS_PHASE}
	DATE_PREFIX "INFO" "Engine: ${CUR_ENGINE} with network: ${CUR_NETWORK} for phase: ${CUR_PHASE} finished!" | tee -a ${LOGS_PHASE}
}

function DATE_PREFIX(){
	INFO_LEVEL=$1
	MESSAGE=$2
	echo "`date '+%Y-%m-%d %H:%M:%S'` ${INFO_LEVEL}  ${MESSAGE}"
}

function ADD_DATE() {
	eval INFO_LEVEL=$1
	while IFS= read -r line; do
		echo "`date +'%Y-%m-%d %H:%M:%S'` ${INFO_LEVEL}  $line"
	done
}

function RUN(){
	LOAD_USER_CONF
	for CUR_ENGINE in ${ENGINE};
	do
		for CUR_NETWORK in ${NETWORK};
		do
			for CUR_PHASE in ${PHASE};
			do
				RUN_NETWORK ${CUR_ENGINE} ${CUR_NETWORK} ${CUR_PHASE}
			done
		done
	done
}

RUN 
