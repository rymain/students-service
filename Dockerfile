# Use latest jboss/base-jdk:11 image as the base
FROM maven:3.6.3-adoptopenjdk-8

ENV WILDFLY_VERSION 14.0.1.Final
ENV WILDFLY_SHA1 757d89d86d01a9a3144f34243878393102d57384
ENV JBOSS_HOME /opt/jboss/wildfly-14.0.1.Final
ENV JBOSS_INSTALL /opt/jboss
ENV postgres_module_dir=/opt/jboss/wildfly-14.0.1.Final/modules/system/layers/base/org/postgres/main
ENV eclipse_module_dir=/opt/jboss/wildfly-14.0.1.Final/modules/system/layers/base/org/eclipse/persistence/main
ENV config_dir=/opt/jboss/wildfly-14.0.1.Final/standalone/configuration/

USER root

RUN groupadd -r jboss -g 1000 && useradd -u 1000 -r -g jboss -m -d /opt/jboss -s /sbin/nologin -c "JBoss user" jboss && \
    chmod 755 /opt/jboss


# Add the WildFly distribution to /opt, and make wildfly the owner of the extracted tar content
# Make sure the distribution is available from a well-known place
RUN cd $HOME \
    && curl -O https://download.jboss.org/wildfly/$WILDFLY_VERSION/wildfly-$WILDFLY_VERSION.tar.gz \
    && sha1sum wildfly-$WILDFLY_VERSION.tar.gz | grep $WILDFLY_SHA1 \
    && tar xf wildfly-$WILDFLY_VERSION.tar.gz \
    && mv $HOME/wildfly-$WILDFLY_VERSION $JBOSS_INSTALL \
    && rm wildfly-$WILDFLY_VERSION.tar.gz \
    && chown -R jboss:0 ${JBOSS_INSTALL} \
    && chmod -R g+rw ${JBOSS_INSTALL}

ENV LAUNCH_JBOSS_IN_BACKGROUND true

USER jboss

# Allow mgmt console access to "root" group
RUN rmdir /opt/jboss/wildfly-14.0.1.Final/standalone/tmp/auth && \
    mkdir -p /opt/jboss/wildfly-14.0.1.Final/standalone/tmp/auth && \
    chmod 775 /opt/jboss/wildfly-14.0.1.Final/standalone/tmp/auth

RUN /opt/jboss/wildfly-14.0.1.Final/bin/add-user.sh admin1 admin1 --silent

# Expose the ports we're interested in
EXPOSE 9990
EXPOSE 8787
EXPOSE 8080

## copy your local .war file assumming that this dockerfile is in the same folder as the .war file.
ADD ./target/gs-rest-service-0.1.0.war /opt/jboss/wildfly-14.0.1.Final/standalone/deployments/gs-rest-service.war

# Set the default command to run on boot
# This will boot WildFly in the standalone mode and bind to all interface
CMD ["/opt/jboss/wildfly-14.0.1.Final/bin/standalone.sh", "-c", "standalone.xml", "-b", "0.0.0.0", "-bmanagement", "0.0.0.0", "--debug"]