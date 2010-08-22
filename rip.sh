#!/bin/bash

VERSION=0.1

set -x
set -e

CDROM='/dev/cdrom'

DISC_INFO=`cd-discid $CDROM`

METADATA_FILE="disc.metadata"

# CDDB protocol used as documented here: http://ftp.freedb.org/pub/freedb/misc/freedb_CDDB_protcoldoc.zip

CDDB_VER=6
CDDB_URL="http://freedb.freedb.org/~cddb/cddb.cgi"
CDDB_USER=`whoami`
CDDB_HOST=`hostname`

# find options for a particular disc or retrieve particular set of metadata
cddb() {
    CDDB_REQUEST="${CDDB_URL}?cmd=cddb+${1}+${2}&hello=${CDDB_USER}+${CDDB_HOST}+$(basename $0)+${VERSION}&proto=${CDDB_VER}"
    echo CDDB lookup: $CDDB_REQUEST
    wget -O "$METADATA_FILE" "$CDDB_REQUEST"
}

cddb query "$DISC_INFO"


CDDB_STATUS="$(head -c3 $METADATA_FILE)"
echo "CDDB Status is $CDDB_STATUS"
if [ "$CDDB_STATUS" -eq 210 ];
then
    # multiple results
    let i=1
    tail -n +2 "$METADATA_FILE" | head -n -1 | awk '{print FNR "\t" $0}'
    read selection
    # TODO: validate selection
    SELECTED_DISC="`tail -n +$((selection+1)) disc.metadata | head -1 | cut -d\  -f 1,2`"
    cddb read "$SELECTED_DISC"
    cat "$METADATA_FILE"

elif [ "$CDDB_STATUS" -eq 211 ];
then
    # multiple results (?)
    echo status 211
elif [ "$CDDB_STATUS" -eq 200 ];
then
    # single result
    echo status 200
else
    # errors
    echo other status
fi
    
