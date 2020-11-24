#!/bin/bash

PURELOC=$HOME/pure/legend-pure/legend-pure-ide-light
CONFIG_LOC=$HOME/pure/legend-pure/legend-pure-ide-light/src/main/resources/ideLightConfig.json

cd $PURELOC && mvn exec:java -Dexec.mainClass="org.finos.legend.pure.ide.light.PureIDEServer" -Dexec.args="server ${CONFIG_LOC}"
