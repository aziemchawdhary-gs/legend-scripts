#!/bin/bash

PURELOC=$HOME/pure/legend-pure
CONFIG_LOC=$HOME/pure/legend-pure/legend-pure-ide-light/src/main/resources/ideLightConfig.json

cd $PURELOC && mvnDebug -pl legend-pure-ide-light exec:java -Dexec.mainClass="org.finos.legend.pure.ide.light.PureIDEServer" -Dexec.args="server ${CONFIG_LOC}"
