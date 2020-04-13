FROM singularities/hadoop:2.7
MAINTAINER Singularities

# Version
ENV SPARK_VERSION=2.4.5

# Set home
ENV SPARK_HOME=/usr/local/spark-$SPARK_VERSION

# 跟新下载源为aliyun
COPY sources.list /etc/apt/sources.list

# apt update操作时提示过期问题: -o Acquire::Check-Valid-Until=false
# Install dependencies
RUN apt-get -o Acquire::Check-Valid-Until=false update \
  && DEBIAN_FRONTEND=noninteractive apt-get install \
    -yq --no-install-recommends  \
      python python3 \
      && apt-get install -yq locales \
      && locale-gen zh_CN.UTF-8 \
      && DEBIAN_FRONTEND=noninteractive dpkg-reconfigure locales \
      && locale-gen zh_CN.UTF-8 \
      && apt-get clean \
      && rm -rf /var/lib/apt/lists/* \
      && /bin/cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
      && echo 'Asia/Shanghai' >/etc/timezone

ENV LANG zh_CN.UTF-8

ENV LANGUAGE zh_CN:zh

ENV LC_ALL zh_CN.UTF-8

# Install Spark
RUN mkdir -p "${SPARK_HOME}" \
  && export ARCHIVE=spark-$SPARK_VERSION-bin-without-hadoop.tgz \
  && export DOWNLOAD_PATH=apache/spark/spark-$SPARK_VERSION/$ARCHIVE \
  && curl -sSL https://mirror.bit.edu.cn/$DOWNLOAD_PATH | \
    tar -xz -C $SPARK_HOME --strip-components 1 \
  && rm -rf $ARCHIVE
COPY spark-env.sh $SPARK_HOME/conf/spark-env.sh
ENV PATH=$PATH:$SPARK_HOME/bin

# Ports
EXPOSE 6066 7077 8080 8081

# Copy start script
COPY start-spark /opt/util/bin/start-spark

# Fix environment for other users
RUN echo "export SPARK_HOME=$SPARK_HOME" >> /etc/bash.bashrc \
  && echo 'export PATH=$PATH:$SPARK_HOME/bin'>> /etc/bash.bashrc

# Add deprecated commands
RUN echo '#!/usr/bin/env bash' > /usr/bin/master \
  && echo 'start-spark master' >> /usr/bin/master \
  && chmod +x /usr/bin/master \
  && echo '#!/usr/bin/env bash' > /usr/bin/worker \
  && echo 'start-spark worker $1' >> /usr/bin/worker \
  && chmod +x /usr/bin/worker
