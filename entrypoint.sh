#!/bin/bash




CONTAINER_ALREADY_STARTED="CONTAINER_ALREADY_STARTED_PLACEHOLDER"
if [ ! -e $CONTAINER_ALREADY_STARTED ]; then
    touch $CONTAINER_ALREADY_STARTED
    echo "-- First container startup : init livy conf --"
	  # Configure Livy based on environment variables
    if [[ -n "${SPARK_MASTER}" ]]; then
      echo "livy.spark.master=${SPARK_MASTER}" >> "${LIVY_CONF_DIR}/livy.conf"
    fi
    if [[ -n "${SPARK_DEPLOY_MODE}" ]]; then
      echo "livy.spark.deploy-mode=${SPARK_DEPLOY_MODE}" >> "${LIVY_CONF_DIR}/livy.conf"
    fi
    if [[ -n "${LOCAL_DIR_WHITELIST}" ]]; then
      echo "livy.file.local-dir-whitelist=${LOCAL_DIR_WHITELIST}" >> "${LIVY_CONF_DIR}/livy.conf"
    fi
    if [[ -n "${ENABLE_HIVE_CONTEXT}" ]]; then
      echo "livy.repl.enable-hive-context=${ENABLE_HIVE_CONTEXT}" >> "${LIVY_CONF_DIR}/livy.conf"
    fi
    if [[ -n "${LIVY_HOST}" ]]; then
      echo "livy.server.host=${LIVY_HOST}" >> "${LIVY_CONF_DIR}/livy.conf"
    fi
    if [[ -n "${LIVY_PORT}" ]]; then
      echo "livy.server.port=${LIVY_PORT}" >> "${LIVY_CONF_DIR}/livy.conf"
    fi
else
    echo "-- Not first container startup : pass init livy conf --"
fi


# test 通过测试端口是否可用，确认服务状态 
wait_until() {
    local hostname=${1?}
    local port=${2?}
    local retry=${3:-100}
    local sleep_secs=${4:-2}
    local address_up=0
    while [ ${retry} -gt 0 ] ; do
        echo  "Livy Waiting until ${hostname}:${port} is up ... with remaining retry times: ${retry}"
        if nc -z ${hostname} ${port}; then
            address_up=1
            break
        fi
        retry=$((retry-1))
        sleep ${sleep_secs}
    done
    if [ $address_up -eq 0 ]; then
        echo "Livy GIVE UP waiting until ${hostname}:${port} is up! "
        return 0
    else
     return 1
	fi
}

# 等待 hdfs 启动
wait_until master 9000 1000000 15
# 等待 hdfs 离开SAFE_MODE
safe_mode_flag="Safe mode is ON"
while [[ "$safe_mode_flag" != "" ]]
do
  safe_mode_flag=$( hdfs dfsadmin -safemode get | grep "Safe mode is ON" )
  sleep 8
  if [[ "$safe_mode_flag" != "" ]]; then 
     echo "HADOOP STATUS: Safe mode is ON"
  else 
     echo "HADOOP STATUS: Safe mode is OFF"
  fi
done

# 启动 livy-server
not_running_flag="not"
while [[ "$safe_mode_flag" == "" && "$not_running_flag" != "" ]]
do
  echo "entry loop,try to start livy-server"
  # 启动 livy 服务
  # "$LIVY_HOME/bin/livy-server" $@
  $LIVY_HOME/bin/livy-server start &
  sleep 5
  not_running_flag=$( $LIVY_HOME/bin/livy-server status | grep "not" )
done

# Blocking call to view all logs. This is what won't let container exit right away.
/scripts/parallel_commands.sh "scripts/watchdir ${LIVY_LOG_DIR}"
