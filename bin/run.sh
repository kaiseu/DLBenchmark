#/bin/bash

CURRENT_DIR=$( cd $( dirname ${BASH_SOURCE[0]} ) && pwd )
BENCHMARK_ROOT=${CURRENT_DIR}/..

## Load User Configurations
USER_CONF_FILE=${BENCHMARK_ROOT}/conf/userSettings.conf
if [[ -f ${USER_CONF_FILE} ]]; then
	echo "==============================================================================================="
        echo "Loading User Configuration file from: ${USER_CONF_FILE} ..."
        source "${USER_CONF_FILE}"
        echo "Loading Done!"
	echo -e "===============================================================================================\n"
else
	 echo "User Configuration file:${USER_CONF_FILE} does not exist, exiting..."
	 exit -1
fi

for CUR_ENGINE in ${ENGINE};
do
	CUR_ENGINE_ROOT=${BENCHMARK_ROOT}/framework/${CUR_ENGINE}
        echo "###############################################################################################"
	echo "Current benchmark engine is: ${CUR_ENGINE}, engine root dir is: ${CUR_ENGINE_ROOT}."

	for CUR_NETWORK in ${NETWORK};
	do
		CUR_NETWORK_ROOT=${CUR_ENGINE_ROOT}/networks/${CUR_NETWORK}
        	echo "***********************************************************************************************"
		echo "Current network to run is: ${CUR_NETWORK}, network root dir is: ${CUR_NETWORK_ROOT}."
		for CUR_PHASE in ${PHASE};
		do
			EXEC_SCRIPT=${CUR_NETWORK_ROOT}/bin/${CUR_PHASE}.sh
			echo "-----------------------------------------------------------------------------------------------"
			echo "Current phase to run is: ${CUR_PHASE}, calling script: ${EXEC_SCRIPT} ..."
			sh ${EXEC_SCRIPT}
			echo "Engine: ${CUR_ENGINE} with network: ${CUR_NETWORK} for phase: ${CUR_PHASE} finished!"
			echo -e "-----------------------------------------------------------------------------------------------\n"
		done
        	echo -e "***********************************************************************************************\n\n"
	done
        echo -e "###############################################################################################\n\n\n\n"
done

