#/bin/bash

CURRENT_DIR=$( cd $( dirname ${BASH_SOURCE[0]} ) && pwd )
BENCHMARK_ROOT=${CURRENT_DIR}/..
LOGS_ROOT=${BENCHMARK_ROOT}/logs
## Import functions
export DLBENCHMARK_FUNCS=${BENCHMARK_ROOT}/scripts/function.sh
if [[ ! -x ${DLBENCHMARK_FUNCS} ]]; then
	chmod +x ${DLBENCHMARK_FUNCS}
fi
source ${DLBENCHMARK_FUNCS}

## Load User Configurations
function LOAD_USER_CONF(){
	USER_CONF_FILE=${BENCHMARK_ROOT}/conf/userSettings.conf
	if [[ -f ${USER_CONF_FILE} ]]; then
		echo "================================================================"
	        DATE_PREFIX "INFO" "Loading User Configuration file from: ${USER_CONF_FILE} ..."
	        source "${USER_CONF_FILE}"
	        DATE_PREFIX "INFO" "Loading Done!"
	else
		DATE_PREFIX "ERROR" "User Configuration file:${USER_CONF_FILE} does not exist, exiting..."
		 exit -1
	fi
}

function RUN_NETWORK(){
	CUR_ENGINE=$1
	CUR_NETWORK=$2
	CUR_PHASE=$3
	LOGS_NETWORK_ROOT=$4
	
	CUR_ENGINE_ROOT=${BENCHMARK_ROOT}/framework/${CUR_ENGINE}
	CUR_NETWORK_ROOT=${CUR_ENGINE_ROOT}/networks/${CUR_NETWORK}
	LOGS_PHASE=${LOGS_NETWORK_ROOT}/${CUR_PHASE}.log
	EXEC_SCRIPT=${CUR_NETWORK_ROOT}/bin/${CUR_PHASE}.sh
	CHECK_EXIST_EXEC ${EXEC_SCRIPT}

	LOAD_USER_CONF >> ${LOGS_PHASE}
	echo "****************************************************************" | tee -a ${LOGS_PHASE}
	DATE_PREFIX "INFO" "Current benchmark engine is: ${CUR_ENGINE}, engine root dir is: ${CUR_ENGINE_ROOT}." | tee -a ${LOGS_PHASE}
	DATE_PREFIX "INFO" "Current network to run is: ${CUR_NETWORK}, network root dir is: ${CUR_NETWORK_ROOT}." | tee -a ${LOGS_PHASE}
	DATE_PREFIX "INFO" "Current phase to run is: ${CUR_PHASE}, calling script: ${EXEC_SCRIPT} ..." | tee -a ${LOGS_PHASE}
	START_TIME=$(date +%s)
	sh ${EXEC_SCRIPT} 2>&1 | tee -a ${LOGS_PHASE}
	END_TIME=$(date +%s)
	ELAPSED_SEC=$(( ${END_TIME} - ${START_TIME} ))
	DATE_PREFIX "INFO" "Engine: ${CUR_ENGINE} with network: ${CUR_NETWORK} for phase: ${CUR_PHASE} finished, elapsed time is: ${ELAPSED_SEC}s" | tee -a ${LOGS_PHASE}
}

#function DATE_PREFIX(){
#	INFO_LEVEL=$1
#	MESSAGE=$2
#	echo -e "`date '+%Y-%m-%d %H:%M:%S'` ${INFO_LEVEL}  ${MESSAGE}"
#}
#
#function ADD_DATE() {
#	eval INFO_LEVEL=$1
#	while IFS= read -r line; do
#		echo "`date +'%Y-%m-%d %H:%M:%S'` ${INFO_LEVEL}  $line"
#	done
#}

function RUN(){
	LOAD_USER_CONF
	for CUR_ENGINE in ${ENGINE};
	do
		for CUR_NETWORK in ${NETWORK};
		do
			LOGS_NETWORK_ROOT=${LOGS_ROOT}/${CUR_ENGINE}/logs-${CUR_ENGINE}-${CUR_NETWORK}-`date +%Y%m%d%H%M%S`
			if [[ ! -d ${LOGS_NETWORK_ROOT} ]]; then
				mkdir -p ${LOGS_NETWORK_ROOT}
			fi

			for CUR_PHASE in ${PHASE};
			do
				RUN_NETWORK ${CUR_ENGINE} ${CUR_NETWORK} ${CUR_PHASE} ${LOGS_NETWORK_ROOT}
			done

			## Backup user settings and local configuration
			LOGS_NETWORK_CONF_ROOT=${LOGS_NETWORK_ROOT}/dlbenchmark-configs
			if [[ ! -d ${LOGS_NETWORK_CONF_ROOT} ]]; then
				 mkdir -p ${LOGS_NETWORK_CONF_ROOT}
			fi
			cp -r ${BENCHMARK_ROOT}/conf/userSettings.conf ${LOGS_NETWORK_CONF_ROOT}
			cp -r ${BENCHMARK_ROOT}/framework/${CUR_ENGINE}/networks/${CUR_NETWORK}/conf/localSetting.conf ${LOGS_NETWORK_CONF_ROOT}
			DATE_PREFIX "INFO" "Logs for engine: ${CUR_ENGINE} with network: ${CUR_NETWORK} have been saved to: ${LOGS_NETWORK_ROOT}"
		done
	done
}

RUN 
