#!/bin/sh

# post_acquire.sh
# Version 1.0

#POST-ACQUISITION SCRIPT TO BE RUN ON SERVER (LINUX)

###########################################################
#USER-DEFINED, SYSTEM VARIABLES:


#LOCATION OF META-DATA EXTRACTION FILES FOR RECORDINGS (AFTER POST-ACQUISITION PROCESSING)


#LOG FILE LOCATION (FOLDER)
LOG_LOCATION="$HOME/log/"

#SYSTEM VARIABLES
PYTHON_VENV="/usr/local/share/behavior/bin/python3"
COMPUTE_HOST=$(hostname)
###########################################################

#CAPTURE ARGUMENTS PASSED TO SCRIPT FROM ACQUISITION COMPUTER
SRC_HOST=""
SRC_IP=""

#DEBUG
#echo "All arguments received: $@"
#echo "Number of arguments: $#"

#PARSE ARGUMENTS
while [[ $# -gt 0 ]]; do
    case "$1" in
        --host)
            SRC_HOST="$2"
            shift 2
            ;;
        --ip)
            SRC_IP="$2"
            shift 2
            ;;
        *)
            echo "Unknown argument: $1"
            exit 1
            ;;
    esac
done

if [[ -z "$SRC_HOST" || -z "$SRC_IP" ]]; then
    echo "Error: Both --host and --ip arguments are required."
    exit 1
fi

echo "Host: $SRC_HOST"
echo "IP: $SRC_IP"
echo "COMPUTE_HOST:\t$COMPUTE_HOST\n"
echo "RUN AS USER: $USER"
###########################################################
#LOG OPTIONS & INIT
DATESTR="%Y-%m-%d %H:%M:%S"
mkdir -p $LOG_LOCATION

TIMESTAMP=$(date +"$DATESTR")
read -r -d '' LOGSTR <<EOF
START post_acquire.sh\n
------------------------------------\n
SRC_HOST:\t$SRC_HOST\n
SRC_IP:\t$SRC_IP\n
COMPUTE_HOST:\t$COMPUTE_HOST\n
SUBMIT_TIMESTAMP:\t$TIMESTAMP\n
------------------------------------\n
EOF

echo -e $LOGSTR > "$LOG_LOCATION/log.txt"

###########################################################
#POST-ACQUISITION PROCESSING (BASED ON HOST)

case "$SRC_HOST" in
  'lil-whisker')
    #TOP CAMERA PROCESS
    echo "Processing for top camera on $SRC_HOST" >> "$LOG_LOCATION/log.txt"
    PROCESS_SCRIPT_LOCATION="/data/behavior/run_top_view.py"
    ;;

  "B6QTE70" | "gyri" | "88QP74G" | "protocerebrum-dk")
    #SIDE CAMERA PROCESS (FOR ALL $SRC_HOST MATCHING PATTERN ABOVE)
    echo "Processing for side camera on $SRC_HOST" >> "$LOG_LOCATION/log.txt"
    PROCESS_SCRIPT_LOCATION="/data/behavior/run_side_view.py"
    ;;

  *)
    #UNKNOWN
    echo "UNKNOWN HOST OR NO POST ACQUISITION PROCESSING REQUIRED" >> "$LOG_LOCATION/log.txt"
    PROCESS_SCRIPT_LOCATION=""
    ;;
esac

# If a process script was set, execute it
if [ -n "$PROCESS_SCRIPT_LOCATION" ]; then
    CMD="$PYTHON_VENV $PROCESS_SCRIPT_LOCATION --host $SRC_HOST --log $LOG_LOCATION/log.txt --user $USER"
    echo "Executing process script: $PROCESS_SCRIPT_LOCATION" >> "$LOG_LOCATION/log.txt"
    $CMD
else
    echo "No process script to execute" >> "$LOG_LOCATION/log.txt"
fi

echo "$(date +"$DATESTR") - POST-ACQUISITION PROCESSING COMPLETED" >> "$LOG_LOCATION/log.txt"

###########################################################

# RUN META-DATA EXTRACTION
# Optional: run a metadata-extraction / consolidation script after processing
# (e.g. to gather instrument settings + notes into a spreadsheet next to the raw
# data). Enable by setting METADATA_SCRIPT_LOCATION (and optionally METADATA_VENV,
# which defaults to PYTHON_VENV) in the environment or above.
METADATA_SCRIPT_LOCATION="${METADATA_SCRIPT_LOCATION:-}"
METADATA_VENV="${METADATA_VENV:-$PYTHON_VENV}"

if [ -n "$METADATA_SCRIPT_LOCATION" ]; then
    echo "$(date +"$DATESTR") - Running metadata extraction: $METADATA_SCRIPT_LOCATION" >> "$LOG_LOCATION/log.txt"
    "$METADATA_VENV" "$METADATA_SCRIPT_LOCATION" --host "$SRC_HOST" --log "$LOG_LOCATION/log.txt" --user "$USER" >> "$LOG_LOCATION/log.txt" 2>&1
else
    echo "$(date +"$DATESTR") - No metadata extraction script configured (set METADATA_SCRIPT_LOCATION to enable)" >> "$LOG_LOCATION/log.txt"
fi

echo "$(date +"$DATESTR") - POST-ACQUISITION WORKFLOW COMPLETED" >> "$LOG_LOCATION/log.txt"

###########################################################
