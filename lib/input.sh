#
# ######################################################################################################################
# DEPLOYER 9000 Input Module
# 
# DESCRIPTION: 	Fetches and validates the INPUT variables provided by GitHub actions
# 
# VERSION: 		1.0
# DATE: 		2025-08-08 
# AUTHOR: 		Black HOST Ltd.
# ######################################################################################################################
#

PROTOCOL="${INPUT_PROTOCOL:-ftp}"						# Define connection type ftp, sftp, ssh 

SERVER="${INPUT_SERVER:?Hostname of IP is required}"	# Require hostname or IP
PORT="${INPUT_PORT:-}"									# Set server connecting protocol 				default: NONE

# AUTHENTICATION RELATED INPUTS
USERNAME="${INPUT_USERNAME:?No user was specified}"		# User authentication
PASSWORD="${INPUT_PASSWORD:-}"							
SSH_KEY="${INPUT_SSH_KEY:-}"							# SSH key used for SFTP & RSYNC transfers

# DIRECTORY DEFAULTS
LOCAL_DIR="${INPUT_LOCAL_DIR:-.}"						# Set the local directory 						default: /app
REMOTE_DIR="${INPUT_REMOTE_DIR:-/}"						# Set the remote upload directory 				default: / ( user home ) 

# FTP/LFTP CONFIG
SECURE="$(to_bool "${INPUT_SECURE:-true}")"				# Switch between FTPS/FTP 						default: true (FTPS)
VERIFY_TLS="$(to_bool "${INPUT_VERIFY_TLS:-true}")"		# Verify SSL certificate  						default: true
PASSIVE="$(to_bool "${INPUT_PASSIVE:-true}")"			# Set FTP passive mode 							default: true
PARALLEL="${INPUT_PARALLEL:-2}"							# Number of concurrent transfers 				default: 2
EXTRA_LFTP="${INPUT_EXTRA_LFTP:-}"						# Extra LFTP config options						default: NONE		

# DATA TRANSFER config
DELETE="$(to_bool "${INPUT_DELETE:-false}")"			# Enable file deletes 							default: false
ONLY_NEWER="$(to_bool "${INPUT_ONLY_NEWER:-true}")"		# SYNC only new files							default: false
EXCLUDE="${INPUT_EXCLUDE:-}"							# List of files to be excluded					default: NONE
DRY_RUN="$(to_bool "${INPUT_DRY_RUN:-false}")"			# Perform a dry run only 						default: false


# REMOTE COMMAND EXECUTION
PRE_SCRIPT="${INPUT_PRE_SCRIPT:-}"						# Run a script prior to the transfers
POST_SCRIPT="${INPUT_POST_SCRIPT:-}"					# Run a script after the transfers
REMOTE_SHELL="${INPUT_REMOTE_SHELL:-/bin/bash -lc}"		# set the remote shell executor


#
# ######################################################################################################################
# INPUT VALIDATORS & HANDLERS
# ######################################################################################################################
#

# if no port is provided failback to the protocol specific ports
if [[ -z "$PORT" ]]; then 
	case "$PROTOCOL" in
		ftp)  PORT="21" ;;
		sftp) PORT="22" ;;
		ssh)  PORT="22" ;;
		*)    die "Unsupported protocol: $PROTOCOL (expected ftp|sftp|ssh)";;
	esac
fi

# normalize LOCAL and REMOTE directory paths
LOCAL_DIR="${LOCAL_DIR%/}"
REMOTE_DIR="${REMOTE_DIR%/}"

# convert excludes into an array
mapfile -t EXCLUDE_ARR < <(echo "$EXCLUDE" | tr ',' '\n' | sed '/^[[:space:]]*$/d' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')