###############################################################################
## Dockerizing Mule EE
## Version:  1.0
## Based on:  Redhat OpenJDK from Docker registry
## FROM registry.access.redhat.com/redhat-openjdk-18/openjdk18-openshift 
###############################################################################

FROM registry.access.redhat.com/redhat-openjdk-18/openjdk18-openshift 
LABEL maintainer="taneng_26@hotmail.com"
 
###############################################################################
## Setting up the arguments
ARG     muleVersion=3.9.1
ARG     muleDistribution=mule-ee-distribution-standalone-$muleVersion.tar.gz
ARG     muleHome=/app/mule-enterprise-standalone-$muleVersion
 
###############################################################################
## MuleEE installation:
USER 0
 
## Install Mule EE - these are the paths inside the Docker.
WORKDIR  /app/

RUN curl -k -O https://s3.amazonaws.com/new-mule-artifacts/$muleDistribution && \
        tar -xvzf $muleDistribution && \
        ln -s $muleHome/ mule && \
        rm -f $muleDistribution

RUN curl -k -O https://s3.amazonaws.com/cdn-anypoint-prod/artifacts/monitoring-center-ui/app/hybrid/am.zip && \
	unzip am.zip -d /app/mule && rm -f /app/am.zip

ADD     ./jq /app/jq
ADD     ./startMule.sh /app/mule/bin/
ADD     ./wrapper.conf /app/mule/conf/
ADD     ./hellodocker-1.0.0-SNAPSHOT.zip /app/mule/apps
   
## Mule  app port
EXPOSE  8081

## Mule Cluster ports
EXPOSE  5701
EXPOSE  54327

RUN mkdir /app/mule/.mule && \
        chmod -R 777 /app/mule/.mule && \
        chmod 755 /app/jq && \
	chmod 755 /app/mule/bin/startMule.sh && \
        chmod -R 777 /app/mule/bin && \
	chmod -R 777 /app/mule/conf && \
        chmod -R 777 /app/mule/logs && \
	chomd -R 777 /app/mule/am &&\
	chmod -R g=u /var /opt && \
	chmod g=u /etc/passwd


## Environment and execution:
ENV             MULE_BASE /app/mule
WORKDIR         /app/mule/bin
ENTRYPOINT      ["/app/mule/bin/startMule.sh"]
CMD ./mule \
        -M-Dwrapper.java.initmemory=$initMemory \
        -M-Dwrapper.java.maxmemory=$maxMemory \
        -M-Danypoint.platform.client_id=$client_id \
        -M-Danypoint.platform.client_secret=$client_secret \
        -M-Dkey=$key \
        -M-Denv=$env \
        $muleRuntimeProxyArgument $startMuleOtherArguments
USER    1001
