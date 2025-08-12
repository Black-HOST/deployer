#
# ######################################################################################################################
# DEPLOYER 9000 SFTP module 
# 
# DESCRIPTION: 	This "module" is a simple `lftp` wrapper which handles deployment via SFTP. 
#				It supports password protected & passwordless SSH key-based authentication and 
#				basic password authentication altho it is not recommended
# 
# VERSION: 		1.0
# DATE: 		2025-08-09 
# AUTHOR: 		Black HOST Ltd.
# ######################################################################################################################
#

SFTP() 
{

	# prep the SSH envirment
	init_ssh

	# build lftp mirroring flags
	mirror_flags

	read -r -d '' LFTP_SCRIPT <<-EOF || true
		set net:max-retries 5;
		set net:reconnect-interval-base 5;
		set net:timeout 30;
		set sftp:auto-confirm yes;
		$EXTRA_LFTP
		mirror ${MIRROR_FLAGS[*]} ${EXCLUDE_ARGS[*]} $LOCAL_DIR $REMOTE_DIR;
		bye
	EOF

	# log SFTP run mode
	log "SFTP -> $SERVER:$PORT (delete=$DELETE, dry-run=$DRY_RUN, parallel=$PARALLEL, local=$LOCAL_DIR, remote=$REMOTE_DIR)"
	
	# execute the transfer
	if [[ -n "$SSH_KEY_PATH" ]]; then
		# key-based authentication
		lftp -u "$USERNAME," -p "$PORT" "sftp://$SERVER" -e "set sftp:connect-program ${SSH_CMD[*]}; $LFTP_SCRIPT"
	else
		# password-based authentication
		lftp -u "$USERNAME","$PASSWORD" -p "$PORT" "sftp://$SERVER" -e "$LFTP_SCRIPT"
	fi
}