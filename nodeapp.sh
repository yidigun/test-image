#!/bin/sh

TMPDIR=/tmp
export TMPDIR

# Node Options
node_bin=`command -v node`
NODE_OPT=${NODE_OPT:-}

CMD=$1; shift
case $CMD in
  start|run)
    if [ -n "$NODEAPP" ]; then
      if [ -f $APPROOT/$NODEAPP ]; then
        exec $node_bin $NODE_OPT $APPROOT/$NODEAPP "$@"
      else
        echo $APPROOT/$NODEAPP is not found. >&2
        exit 1
      fi
    else
      echo "\$NODEAPP is not specified. Add ENV parameter. (eg: -e NODEAPP=app.js)"
      exit 1
    fi
    ;;

  sh|bash|/bin/sh|/bin/bash|/usr/bin/bash)
    exec /bin/sh "$@"
    ;;

  *)
    echo usage: "$0 { start|run [ args ... ] | sh [ args ... ] }"
    ;;

esac
