#!/bin/sh

# Modified by Stan Schwertly to download locally rather than to send to Posterous

# This software is licensed under the Creative Commons GNU GPL version 2.0 or later.
# License informattion: http://creativecommons.org/licenses/GPL/2.0/

# This script is a derivative of the original, obtained from here:
# http://tuxbox.blogspot.com/2010/03/twitpic-to-posterous-export-script.html

RUN_DATE=`date +%F--%H-%m-%S`
SCRIPT_VERSION_STRING="v1.0"

TP_NAME=$1
WORKING_DIR=$2

IMG_DOWNLOAD=1
PREFIX=twitpic-$TP_NAME
HTML_OUT=$PREFIX-all-$RUN_DATE.html

if [ -z "$TP_NAME" ]; then
  echo "You must supply a TP_NAME."
  exit
fi
if [ ! -d "$WORKING_DIR" ]; then
  echo "You must supply a WORKING_DIR."
  exit
fi

cd $WORKING_DIR

if [ -f "$HTML_OUT" ]; then
  rm -v $HTML_OUT
fi

IMAGES=
if [ ! -d "images" ]; then
  mkdir images;
fi

MORE=1
PAGE=1
while [ $MORE -ne 0 ]; do
  echo PAGE: $PAGE
  FILENAME=$PREFIX-page-$PAGE.html
  if [ ! -f $FILENAME ]; then
    wget http://twitpic.com/photos/${TP_NAME}?page=$PAGE -O $FILENAME
  fi
  if [ -z "`grep "More photos &gt;" $FILENAME`" ]; then
    MORE=0
  else
    PAGE=`expr $PAGE + 1`
  fi
done

ALL_IDS=`cat $PREFIX-page-* | grep -Eo "<a href=\"/[a-zA-Z0-9]+\">" | grep -Eo "/[a-zA-Z0-9]+" | grep -Eo "[a-zA-Z0-9]+" | sort -r | xargs`

COUNT=0
LOG_FILE=$PREFIX-log-$RUN_DATE.txt

echo $ALL_IDS | tee -a $LOG_FILE

for ID in $ALL_IDS; do
  COUNT=`expr $COUNT + 1`
  echo $ID: $COUNT | tee -a $LOG_FILE

  echo "Processing $ID..."
  FULL_HTML=$PREFIX-$ID-full.html
  if [ ! -f "$FULL_HTML" ]; then
    wget http://twitpic.com/$ID/full -O $FULL_HTML
  fi

 FULL_URL=`grep "<img src" $FULL_HTML | grep -Eo "src=\"[^\"]*\"" | grep -Eo "http://[^\"]*"`

  if [ "$IMG_DOWNLOAD" -eq 1 ]; then
    EXT=`echo "$FULL_URL" | grep -Eo "[a-zA-Z0-9]+\.[a-zA-Z0-9]+\?" | head -n1 | grep -Eo "\.[a-zA-Z0-9]+"`
    if [ -z "$EXT" ]; then
      EXT=`echo "$FULL_URL" | grep -Eo "\.[a-zA-Z0-9]+$"`
    fi
    FULL_FILE=$PREFIX-$ID-full$EXT
    if [ ! -f "images/$FULL_FILE" ]; then
      wget "$FULL_URL" -O "images/$FULL_FILE"
    fi
  fi
done

