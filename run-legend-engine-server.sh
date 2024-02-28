#!/bin/bash

ENGINELOC=$HOME/pure/legend-engine
CONFIG_LOC=$HOME/pure/legend-engine/legend-engine-config/legend-engine-server/config/config.json


export MAVEN_OPTS="-Dfile.encoding=UTF8 -agentlib:jdwp=transport=dt_socket,address=8000,server=y,suspend=n"
cd $ENGINELOC && mvn -pl legend-engine-config/legend-engine-server exec:java -Dexec.mainClass="org.finos.legend.engine.server.Server" -Dexec.args="server ${CONFIG_LOC}"
