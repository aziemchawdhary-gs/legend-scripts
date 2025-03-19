#!/bin/bash

PURELOC=${1:-$HOME/pure/legend-engine}
CONFIG_LOC=$PURELOC/legend-engine-core/legend-engine-core-pure/legend-engine-pure-ide/legend-engine-pure-ide-light-http-server/src/main/resources/ideLightConfig.json



export MAVEN_OPTS="-Dfile.encoding=UTF8 -agentlib:jdwp=transport=dt_socket,address=8000,server=y,suspend=n -Dpure.option.DebugPlatformCodeGen=true -Dpure.option.PlanLocal=true -Dpure.option.ExecPlan=true -Dpure.option.ShowLocalPlan=true -Dpure.option.IncludeAlloyOnlyTests=true"
#$muuumexport MAVEN_OPTS="-Dpure.option.DebugPlatformCodeGen=true -Dpure.option.PlanLocal=true -Dpure.option.ExecPlan=true -Dpure.option.ShowLocalPlan=true -Dpure.option.IncludeAlloyOnlyTests=true -Dlegend.test.clientVersion=vX_X_X -Dlegend.test.serverVersion=v1 -Dlegend.test.serializationKind=json -Dlegend.test.server.host=127.0.0.1 -Dlegend.test.server.port=6300"
# export MAVEN_OPTS="-Dlegend.test.server.port=6300"
cd $PURELOC && mvn -pl legend-engine-core/legend-engine-core-pure/legend-engine-pure-ide/legend-engine-pure-ide-light-http-server exec:java -Dexec.mainClass="org.finos.legend.engine.ide.PureIDELight" -Dexec.args="server ${CONFIG_LOC}"
m
