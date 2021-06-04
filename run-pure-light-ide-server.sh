#!/bin/bash

PURELOC=$HOME/projects/pure/legend-pure
CONFIG_LOC=$HOME/projects/pure/legend-pure/legend-pure-ide-light/src/main/resources/ideLightConfig.json

export MAVEN_OPTS="-Dpure.option.DebugPlatformCodeGen=true -Dpure.option.PlanLocal=true -Dpure.option.ExecPlan=true -Dpure.option.ShowLocalPlan=true -Dpure.option.IncludeAlloyOnlyTests=true -Dlegend.test.clientVersion=vX_X_X -Dlegend.test.serverVersion=v1 -Dlegend.test.serializationKind=json -Dlegend.test.server.host=localhost -Dlegend.test.server.port=6060"
cd $PURELOC && mvn -pl legend-pure-ide-light exec:java -Dexec.mainClass="org.finos.legend.pure.ide.light.PureIDEServer" -Dexec.args="server ${CONFIG_LOC}"
