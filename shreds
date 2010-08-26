#!/bin/bash

#set -x
set -e

VERSION=0.1
EDITOR=emacs
WORKDIR=$PWD

CDROM='/dev/cdrom'
OFFSET=697

ENCODED_ROOT="/home/maciek/Desktop/rip.sh"
ENCODE_OPTS="-V 2 --id3v2-only"

# TODO: take option
TRACK_OFFSET=0

DISC_INFO=`cd-discid $CDROM`
DISC_ID=`echo $DISC_INFO | cut -d\  -f1`

# CDDB protocol used as documented here: http://ftp.freedb.org/pub/freedb/misc/freedb_CDDB_protcoldoc.zip and
# here http://ftp.freedb.org/pub/freedb/latest/DBFORMAT
CDDB_VER=6
CDDB_URL="http://freedb.freedb.org/~cddb/cddb.cgi"
CDDB_USER=`whoami`
CDDB_HOST=`hostname`

# Issue a remote CDDB command (if not cached); arguments are the command in question and its arguments (as a single parameter)
cddb() {
    #TODO: just echo the filename instead of using a separate function
    FILENAME=`cddb_file "$1" "$2"`
    CDDB_REQUEST="${CDDB_URL}?cmd=cddb+${1}+${2}&hello=${CDDB_USER}+${CDDB_HOST}+$(basename $0)+${VERSION}&proto=${CDDB_VER}"
    echo CDDB request: $CDDB_REQUEST
    test -f "$FILENAME" || wget -O "$FILENAME" "$CDDB_REQUEST"
}

cddb_file() {
    echo "$2.${1}" | tee result-filename # | sed -r 's/\s+/_/g' 
}

cddb query "$DISC_INFO"
CDDB_LISTING="`cddb_file query \"$DISC_INFO\"`"
CDDB_STATUS=$(head -c3 "$CDDB_LISTING")
SELECTED_DISC=
echo "cddb query status is $CDDB_STATUS"
if [ "$CDDB_STATUS" -eq 210 -o "$CDDB_STATUS" -eq 211 ];
then
    # multiple results (exact or inexact)
    let i=1
    echo "Select disc metadata:"
    tail -n +2 "$CDDB_LISTING" | head -n -1 | awk '{print FNR "\t" $0}'
    read SELECTED_INDEX
    SELECTED_DISC="`tail -n +$((SELECTED_INDEX+1)) "$CDDB_LISTING" | head -1 | cut -d\  -f 1,2`"
elif [ "$CDDB_STATUS" -eq 200 ];
then
    # single result
    SELECTED_DISC="`cut -d\  -f2,3 \"$CDDB_LISTING\"`"
else
    # errors
    echo "ERROR: Unrecognized status."
    exit $CDDB_STATUS
fi

cddb read "$SELECTED_DISC"
CDDB_METADATA="`cddb_file read \"$SELECTED_DISC\"`"
CDDB_STATUS="$(head -c3 "$CDDB_METADATA")"
METADATA_FILE=`mktemp`

# generate a file with
# - album artist
# - album title
# - year
# - genre
# - track no.
# - artist
# - title
# for each track

DTITLE="$(sed -r -n 's_^DTITLE=(.*)$_\1_p' "$CDDB_METADATA" | tr -d '\r')"
# Bash string mangling: this strips the longest trailing match
# and shortest leading match (since cut can't handle a multi-char delimiter)
ALBUM_ARTIST="${DTITLE%% / *}"
ALBUM_TITLE="${DTITLE#* / }"
YEAR="$(sed -r -n 's_^DYEAR=(.*)_\1_p' "$CDDB_METADATA" | tr -d '\r')"
GENRE="$(sed -r -n 's_^DGENRE=(.*)_\1_p' "$CDDB_METADATA" | tr -d '\r')"

echo "Metadata is $ALBUM_ARTIST $ALBUM_TITLE $YEAR $GENRE"

let i=$TRACK_OFFSET+1
grep "^TTITLE" "$CDDB_METADATA" | while read track;
do
    # Note that this is not going to apply to all discs: some non-VA
    # discs use ' / ' as a general-purpose delimiter, so we test the album artist.
    TRACK_NO=$i
    TRACK_INFO="$(echo $track | sed -r -n 's_^TTITLE[0-9]{1,3}=(.*)$_\1_p' | tr -d '\r')"
    if $(echo "$ALBUM_ARTIST" | grep -i '^Various' &>/dev/null);
    then
	# See above: we're playing fast and loose with the delimiter at the moment
	TRACK_ARTIST="${TRACK_INFO%% / *}"
	TRACK_TITLE="${TRACK_INFO#* / }"
    else
	TRACK_ARTIST="$ALBUM_ARTIST"
	TRACK_TITLE="$TRACK_INFO"
    fi
    # If you have embedded tabs in your music metadata, FSM help you
    echo -e "${ALBUM_ARTIST}\t${ALBUM_TITLE}\t${YEAR}\t${GENRE}\t${TRACK_NO}\t${TRACK_ARTIST}\t${TRACK_TITLE}" >> "$METADATA_FILE"
    let i+=1
done

cat "$METADATA_FILE"
#$EDITOR "$METADATA_FILE"

while IFS=$'\011' read alb_artist alb_title year genre track_no artist title
do
    WAV_FILE=`mktemp`
    # rip command: cdparanoia [.160517]- -d /dev/cdrom -O 697 "/home/maciek/Desktop/Crosby, Stills & Nash/temp_sr0/track10_2.wav" 2>&1
    cdparanoia $track_no -d "$CDROM" -O $OFFSET "$WAV_FILE"
# encode command: lame -V 2 --id3v2-only --tl "Velocifero" --ty "2008" --tg "Electronic" --tv TXXX=DISCID="a50cc30d" --ta "Ladytron" --tt "Deep Blue" --tn 11/13 "/home/maciek/Desktop/Ladytron/temp_sr0/track11_1.wav" "/home/maciek/Desktop/Ladytron/Velocifero/11-Deep Blue.mp3" 2>&1
    ENCODED_DIR="${ENCODED_ROOT}/${alb_artist}/${alb_title}"
    mkdir -p "$ENCODED_DIR"
    # TODO: set album artist for VA albums
    lame $ENCODE_OPTS --tv TXXX=DISCID="$DISC_ID" --tl "$alb_title" --ty "$year" --tg "$genre" --ta "$artist" --tt "$title" --tn "$track_no" "$WAV_FILE" "$ENCODED_DIR/$(printf "%02d" $track_no)-${title}"
done < "$METADATA_FILE"

#if [ "$CLEANUP" ];
#then
#    # remove metadata files and track files
#fi




