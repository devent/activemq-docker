FROM java:8

# Configuration variables.
ENV ACTIVEMQ_VERSION 5.14.3
ENV ACTIVEMQ_HOME /opt/activemq
ENV ACTIVEMQ_ARCHIVE apache-activemq-${ACTIVEMQ_VERSION}-bin.tar.gz
ENV ACTIVEMQ_URL http://apache.mirrors.ovh.net/ftp.apache.org/dist/activemq/${ACTIVEMQ_VERSION}/apache-activemq-${ACTIVEMQ_VERSION}-bin.tar.gz
ENV LOG_DIR /var/log/activemq
ENV DATA_DIR /data/activemq
ENV START_SCRIPT $ACTIVEMQ_HOME/bin/linux-x86-64/activemq
ENV WRAPPER_CONF $ACTIVEMQ_HOME/bin/linux-x86-64/wrapper.conf

# Install xmlstarlet to configure the activeMQ XML files.
RUN set -x \
    && apt-get update --quiet \
    && apt-get install --quiet --yes --no-install-recommends ca-certificates curl libtcnative-1 xmlstarlet \
    && apt-get clean \
    && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    && curl -o /usr/local/bin/gosu -SL "https://github.com/tianon/gosu/releases/download/1.10/gosu-$(dpkg --print-architecture)" \
    && curl -o /usr/local/bin/gosu.asc -SL "https://github.com/tianon/gosu/releases/download/1.10/gosu-$(dpkg --print-architecture).asc" \
    && gpg --verify /usr/local/bin/gosu.asc \
    && rm /usr/local/bin/gosu.asc \
    && chmod +x /usr/local/bin/gosu

# Only for development.
COPY $ACTIVEMQ_ARCHIVE /tmp/$ACTIVEMQ_ARCHIVE

# Install activeMQ.
RUN set -x \
    && cd "/tmp" \
    # Download if no local file is available.
    && if [ -z "`find $ACTIVEMQ_ARCHIVE -size +0`" ]; then curl -LO "${ACTIVEMQ_URL}"; fi \
    && tar -xzf apache-activemq-${ACTIVEMQ_VERSION}-bin.tar.gz \
    && mv apache-activemq-${ACTIVEMQ_VERSION} ${ACTIVEMQ_HOME} \
    && mkdir -p "${DATA_DIR}" \
    && mkdir -p "${LOG_DIR}" \
    && chmod u=rwX,g=rX,o=rX -R ${ACTIVEMQ_HOME} \
    && chmod u=rwX,g=rwX,o=rwX -R "${ACTIVEMQ_HOME}/data"

# Fix ActiveMQ.
RUN set -x \
    && sed -ri "s/^\s+su -m/gosu/" "${START_SCRIPT}" \
    && sed -ri "s|^PIDDIR.*|PIDDIR=\"${DATA_DIR}\"|" "${START_SCRIPT}" 

# Configure directories in wrapper.conf.
RUN set -x \
    && sed -ri "s|^set\\.default\\.ACTIVEMQ_DATA=.*|set.default.ACTIVEMQ_DATA=${DATA_DIR}|" "${WRAPPER_CONF}" \
    && sed -ri "s|^wrapper\\.logfile=.*|wrapper.logfile=${LOG_DIR}/wrapper.log|" "${WRAPPER_CONF}"

# Expose activeMQ ports.
EXPOSE 8161
EXPOSE 61616
EXPOSE 5672
EXPOSE 61613
EXPOSE 1883
EXPOSE 61614

# Expose activeMQ directories.
VOLUME ["/data/activemq"]
VOLUME ["/var/log/activemq"]

# Set the default working directory as the installation directory.
WORKDIR /opt/activemq

# Set the docker entry point script.
COPY "docker-entrypoint.sh" "/"
ENTRYPOINT ["/docker-entrypoint.sh"]

# Add configuration.
COPY conf/activemq.xml $ACTIVEMQ_HOME/conf/activemq.xml
COPY conf/jetty.xml $ACTIVEMQ_HOME/conf/jetty.xml

# Run activeMQ as a foreground process by default.
CMD ["/opt/activemq/bin/linux-x86-64/activemq", "console"]
