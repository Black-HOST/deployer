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
	# build lftp mirroring & exclude flags
	lftp_flags

	# disable SSL verification
	local SSL_VERIFY="yes"; [[ "$VERIFY_TLS" == "false" ]] && SSL_VERIFY="no"

	# generate LFTP connection script 
	read -r -d '' LFTP_SCRIPT <<-EOF || true
		set net:max-retries 5;
		set net:reconnect-interval-base 5;
		set net:timeout 30;
		set ftp:passive-mode $PASSIVE;
		set ftp:ssl-force $SECURE;
		set ftp:ssl-protect-data $SECURE;
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