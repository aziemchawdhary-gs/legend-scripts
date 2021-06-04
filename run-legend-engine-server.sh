#!/bin/bash

ENGINELOC=$HOME/projects/pure/legend-engine
CONFIG_LOC=$HOME/projects/pure/legend-engine/legend-engine-server/src/test/resources/org/finos/legend/engine/server/test/userTestConfig.json


export MAVEN_OPTS="-Dfile.encoding=UTF8"
cd $ENGINELOC && mvn -pl legend-engine-server exec:java -Dexec.mainClass="org.finos.legend.engine.server.Server" -Dexec.args="server ${CONFIG_LOC}"
