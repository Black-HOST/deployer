#
# ######################################################################################################################
# DEPLOYER 9000 Input Module
#
# DESCRIPTION: 	Fetches and validates the configuration options from the environment: <OPTION> (GitLab CI,
#				docker run, compose) or INPUT_<OPTION> (set by GitHub Actions), the plain name wins.
#
# VERSION: 		1.0
# DATE: 		2025-08-08
# AUTHOR: 		Black HOST Ltd.
# ######################################################################################################################
#

PROTOCOL="$(opt PROTOCOL ftp)"							# Define connection type ftp, sftp, ssh

SERVER="$(opt SERVER)"									# Require hostname or IP
PORT="$(opt PORT)"										# Set server connecting protocol 				default: NONE

# AUTHENTICATION RELATED INPUTS
USERNAME="$(opt USERNAME)"								# User authentication
PASSWORD="$(opt PASSWORD)"
SSH_KEY="$(opt SSH_KEY)"								# SSH key used for SFTP & RSYNC transfers

# DIRECTORY DEFAULTS
LOCAL_DIR="$(opt LOCAL_DIR .)"							# Set the local directory 						default: /app
REMOTE_DIR="$(opt REMOTE_DIR /)"						# Set the remote upload directory 				default: / ( user home )

# FTP/LFTP CONFIG
SECURE="$(to_bool "$(opt SECURE true)")"				# Switch between FTPS/FTP 						default: true (FTPS)
VERIFY_TLS="$(to_bool "$(opt VERIFY_TLS true)")"		# Verify SSL certificate  						default: true
PASSIVE="$(to_bool "$(opt PASSIVE true)")"				# Set FTP passive mode 							default: true
PARALLEL="$(opt PARALLEL 2)"							# Number of concurrent transfers 				default: 2
EXTRA_LFTP="$(opt EXTRA_LFTP)"							# Extra LFTP config options						default: NONE

# DATA TRANSFER config
DELETE="$(to_bool "$(opt DELETE false)")"				# Enable file deletes 							default: false
ONLY_NEWER="$(to_bool "$(opt ONLY_NEWER false)")"		# SYNC only new files							default: false
DRY_RUN="$(to_bool "$(opt DRY_RUN false)")"				# Perform a dry run only 						default: false
PRESERVE_TIMES="$(to_bool "$(opt PRESERVE_TIMES false)")"	# Deploy files with their git commit times		default: false

# DEFAULT EXCLUDE LIST
EXCLUDE="$(opt EXCLUDE '.*,.*/,node_modules/,*.log')"
INCLUDE="$(opt INCLUDE)"									# Deploy even when excluded					default: NONE

# REMOTE COMMAND EXECUTION
PRE_SCRIPT="$(opt PRE_SCRIPT)"							# Run a script prior to the transfers
POST_SCRIPT="$(opt POST_SCRIPT)"						# Run a script after the transfers
REMOTE_SHELL="$(opt REMOTE_SHELL '/bin/bash -lc')"		# set the remote shell executor


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
		rsync)  PORT="22" ;;
		*)    die "Unsupported protocol: $PROTOCOL (expected ftp|sftp|rsync|ssh)";;
	esac
fi

# normalize LOCAL and REMOTE directory paths
LOCAL_DIR="${LOCAL_DIR%/}"
REMOTE_DIR="${REMOTE_DIR%/}"

# convert excludes and includes into arrays
mapfile -t INCLUDE_ARR < <(echo "$INCLUDE" | sed -e 's/[ \t]*,[ \t]*/\n/g' | sed '/^$/d')
mapfile -t EXCLUDE_ARR < <(echo "$EXCLUDE" | sed -e 's/[ \t]*,[ \t]*/\n/g' | sed '/^$/d')