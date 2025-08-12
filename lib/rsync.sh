#
# ######################################################################################################################
# DEPLOYER 9000 RSYNC module 
# 
# DESCRIPTION: 	This "module" is a simple `rsync` wrapper which handles file deployments via rsync. 
#				It supports password protected & passwordless SSH key-based authentication and 
#				basic password authentication altho it is not recommended
# 
# VERSION: 		1.0
# DATE: 		2025-08-09 
# AUTHOR: 		Black HOST Ltd.
# ######################################################################################################################
#

RSYNC() 
{
	# prep the SSH envirment
	init_ssh

	# build rsync mirroring flags
	mirror_flags rsync

	log "RSYNC/SSH -> $SERVER:$PORT (delete=$DELETE, dry-run=$DRY_RUN, local_dir=$LOCAL_DIR, remote_dir=$REMOTE_DIR"

	rsync "${MIRROR_FLAGS[@]}" "${EXCLUDE_ARGS[@]}" -e "${SSH_CMD[*]}" "$LOCAL_DIR"/ "$USERNAME@$SERVER:$REMOTE_DIR"/
}