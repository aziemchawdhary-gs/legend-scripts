#!/bin/bash

ROOTLOC=$HOME/pure
LEGEND_PURE_LOC=$ROOTLOC/legend-pure
LEGEND_ENGINE_LOC=$ROOTLOC/legend-engine

cd $LEGEND_PURE_LOC
echo 'Updating version of legend-pure to $USER-SNAPSHOT'
mvn versions:set -DnewVersion=$USER-SNAPSHOT

echo 'Building legend-pure'
mvn clean install -DskipTests -T2

notify-send -u CRITICAL "Legend-Pure build completed!"

cd $LEGEND_ENGINE_LOC
echo 'Updating legend-engine dependency on legend-pure'
mvn versions:set-property -Dproperty=legend.pure.version -DnewVersion=$USER-SNAPSHOT

echo 'Building legend-engine'
mvn clean install -DskipTests -T2

notify-send -u CRITICAL "Legend-Engine build completed!"

