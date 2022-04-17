FROM lisacumt/bigdata_base_env_img:1.1.2 as base_package

ENV LIVY_VERSION=0.8.0-incubating
ENV LIVY_HOME=/usr/program/livy
ENV LIVY_CONF_DIR="${LIVY_HOME}/conf"
ENV LIVY_LOG_DIR="${LIVY_HOME}/logs"
ENV LIVY_PACKAGE="apache-livy-${LIVY_VERSION}-bin.zip"

######################################################################
FROM base_package as application_package
ENV USR_PROGRAM_DIR=/usr/program
ENV USR_BIN_DIR="${USR_PROGRAM_DIR}/source_dir"
RUN mkdir -p "${USR_BIN_DIR}"
# 使用本地的源文件，加快rebuild速度，方便调试
COPY tar-source-files/* "${USR_PROGRAM_DIR}/source_dir"/
WORKDIR "${USR_PROGRAM_DIR}/source_dir"

# 国内加速地址，没找到
# 如果${USR_PROGRAM_DIR}/source_dir不存在，则下载
RUN if [ ! -f "${LIVY_PACKAGE}" ]; then curl --progress-bar -L --retry 3 \
    "http://archive.apache.org/dist/incubator/livy/${LIVY_VERSION}/${LIVY_PACKAGE}" -o "${USR_PROGRAM_DIR}/source_dir/${LIVY_PACKAGE}" ; fi \
  && unzip -qq "${USR_PROGRAM_DIR}/source_dir/${LIVY_PACKAGE}" -d "${USR_PROGRAM_DIR}" \
  && mv "${USR_PROGRAM_DIR}/apache-livy-${LIVY_VERSION}-bin" "${LIVY_HOME}" \
  && mkdir -p "${LIVY_LOG_DIR}" \
  && chown -R root:root "${LIVY_HOME}" \
  && chmod +755 -R "${LIVY_HOME}" \
  && rm -rf "${USR_PROGRAM_DIR}/source_dir/*" 

######################################################################
FROM base_package
COPY --from=application_package "${LIVY_HOME}"/ "${LIVY_HOME}"/
COPY conf/livy.conf "${LIVY_CONF_DIR}"/
RUN mkdir -p "${HADOOP_CONF_DIR}" \
 && mkdir -p "${HIVE_CONF_DIR}" \
 && mkdir -p "${HBASE_CONF_DIR}" \
 && mkdir -p "${SPARK_CONF_DIR}" \
 && mkdir -p "/scripts/"

COPY --from=lisacumt/hadoop-hive-hbase-spark-docker:1.1.2 "${HADOOP_HOME}"/ "${HADOOP_HOME}"/
COPY --from=lisacumt/hadoop-hive-hbase-spark-docker:1.1.2 "${HIVE_CONF_DIR}"/ "${HIVE_CONF_DIR}"/
COPY --from=lisacumt/hadoop-hive-hbase-spark-docker:1.1.2 "${HBASE_CONF_DIR}"/ "${HBASE_CONF_DIR}"/
COPY --from=lisacumt/hadoop-hive-hbase-spark-docker:1.1.2 "${SPARK_HOME}"/ "${SPARK_HOME}"/
COPY --from=lisacumt/hadoop-hive-hbase-spark-docker:1.1.2 "${TEZ_HOME}"/ "${TEZ_HOME}"/
COPY --from=lisacumt/hadoop-hive-hbase-spark-docker:1.1.2 /scripts/* /scripts/

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh




HEALTHCHECK CMD curl -f "http://host.docker.internal:${LIVY_PORT}/" || exit 1

ENTRYPOINT ["/entrypoint.sh"]
