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

	# restore the commit times of the tracked files
	preserve_times

	# fail-exit stops on the first error and `cd .` forces a login before mirroring: a --dry-run mirror never contacts the server on its own and exits 0
	read -r -d '' LFTP_SCRIPT <<-EOF || true
		set cmd:fail-exit yes;
		set net:max-retries 5;
		set net:reconnect-interval-base 5;
		set net:timeout 30;
		set sftp:auto-confirm $([[ -n "$HOST_KEY" ]] && echo no || echo yes);
		$EXTRA_LFTP
		cd .;
		mirror ${MIRROR_FLAGS[*]} ${EXCLUDE_ARGS[*]} ${INCLUDE_ARGS[*]} $LOCAL_DIR $REMOTE_DIR;
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
		LFTP_PASSWORD="$PASSWORD" lftp --env-password -u "$USERNAME" -p "$PORT" "sftp://$SERVER" -e "$LFTP_SCRIPT"
	fi
}