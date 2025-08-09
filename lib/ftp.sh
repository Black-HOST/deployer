#
# ######################################################################################################################
# DEPLOYER 9000 FTP/FTPS module 
# 
# DESCRIPTION: 	This "module" is a simple `lftp` wrapper which handles deployment via FTP or FTPS. 
#				It is secure by design, enforcing FTPS and TLS/SSL certificate validation.
# 
# VERSION: 		1.0
# DATE: 		2025-08-08 
# AUTHOR: 		Black HOST Ltd.
# ######################################################################################################################
#

FTP() 
{
	# build lftp  mirroring flags
	local MIRROR_FLAGS=(-R --verbose --parallel="$PARALLEL")
	[[ "$DELETE" == "true" ]]    && MIRROR_FLAGS+=(--delete)
	[[ "$ONLY_NEWER" == "true" ]]&& MIRROR_FLAGS+=(--only-newer)
	[[ "$DRY_RUN" == "true" ]]   && MIRROR_FLAGS+=(--dry-run)

	# generate the exclude argguments
	local EXCLUDE_ARGS=()
	for path in "${EXCLUDE_ARR[@]}"; do
	  EXCLUDE_ARGS+=(--exclude-glob "$path")
	done

	# set FTP passive mode
	local PASSIVE_MODE="true"; [[ "$(to_bool "$PASSIVE")" == "false" ]] && PASSIVE_MODE="false"

	# force SSL connections 
	local FTP_SSL_FORCE="false"
	local FTP_SSL_PROTECT_DATA="false"

	if [[ "$SECURE" == "true" ]]; then
	  FTP_SSL_FORCE="true"
	  FTP_SSL_PROTECT_DATA="true"
	fi

	# disable SSL verification
	local SSL_VERIFY="yes"; [[ "$VERIFY_TLS" == "false" ]] && SSL_VERIFY="no"

	# generate LFTP connection script 
	local LFTP_SCRIPT

	read -r -d '' LFTP_SCRIPT <<EOF || true
	set net:max-retries 5;
	set net:reconnect-interval-base 5;
	set net:timeout 30;
	set ftp:passive-mode $PASSIVE_MODE;
	set ftp:ssl-force $FTP_SSL_FORCE;
	set ftp:ssl-protect-data $FTP_SSL_PROTECT_DATA;
	set ssl:verify-certificate $SSL_VERIFY;
	$EXTRA_LFTP
	mirror ${MIRROR_FLAGS[*]} ${EXCLUDE_ARGS[*]} $LOCAL_DIR $REMOTE_DIR;
	bye
EOF

	# log FTP/S run mode
	log "FTP$([[ "$SECURE" == "true" ]] && echo 'S') -> $SERVER:$PORT (delete=$DELETE, dry-run=$DRY_RUN, parallel=$PARALLEL, local=$LOCAL_DIR, remote=$REMOTE_DIR)"
	
	# execute the transfer
	lftp -u "$USERNAME","$PASSWORD" -p "$PORT" "$SERVER" -e "$LFTP_SCRIPT"
}