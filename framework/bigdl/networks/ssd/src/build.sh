#! /bin/bash
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

DATE_PREFIX "INFO" "Start to build ..."
## Build module models
cd ${CURRENT_DIR}/models
mvn clean install

if [[ $? == 0 ]]; then
	DATE_PREFIX "INFO" "Build module models done!"
else
	DATE_PREFIX "ERROR" "Build module models failed, exiting ..."
	exit -2
fi
cd - >> /dev/null 2>&1
## Build SSD
cd ${CURRENT_DIR}/objectDetection
mvn clean package -DskipTests

if [[ $? == 0 ]]; then
	DATE_PREFIX "INFO" "Build SSD from source code finished successfully!"
	cp -r ${CURRENT_DIR}/objectDetection/dist/target/object-detection-0.1-SNAPSHOT-jar-with-dependencies-and-spark.jar ${SSD_JARS_PATH}
	DATE_PREFIX "INFO" "Executable jar has been copied to ${SSD_JARS_PATH}"
else
	DATE_PREFIX "ERROR" "Build failed, exiting ..."
	exit -3
fi

cd - >> /dev/null 2>&1
