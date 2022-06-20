#!/bin/bash

PURELOC=$HOME/pure/legend-engine
CONFIG_LOC=$HOME/pure/legend-engine/legend-engine-pure-ide-light/src/main/resources/ideLightConfig.json

export MAVEN_OPTS="-Dpure.option.DebugPlatformCodeGen=true -Dpure.option.PlanLocal=true -Dpure.option.ExecPlan=true -Dpure.option.ShowLocalPlan=true -Dpure.option.IncludeAlloyOnlyTests=true -Dlegend.test.clientVersion=vX_X_X -Dlegend.test.serverVersion=v1 -Dlegend.test.serializationKind=json -Dlegend.test.server.host=localhost -Dlegend.test.server.port=6060"
cd $PURELOC && mvn -pl legend-engine-pure-ide-light exec:java -Dexec.mainClass="org.finos.legend.engine.ide.PureIDELight" -Dexec.args="server ${CONFIG_LOC}"
