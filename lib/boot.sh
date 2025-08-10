#
# ######################################################################################################################
# DEPLOYER 9000 BOOT SCRIPT
# 
# DESCRIPTION: 	Initialize DEPLOYER 9000 core and helpers
# 
# VERSION: 		1.0
# DATE: 			2025-08-08 
# AUTHOR: 		Black HOST Ltd.
# ######################################################################################################################
#


#
# ######################################################################################################################
# HELPER FUNCTIONS
# ######################################################################################################################
#
	# OUTPUT LOGGERS
	log() { echo "[DEPLOYER] $*"; }
	err() { echo "[DEPLOYER] Error: $*" >&2; }
	die() { err "$@"; exit 1; }

	# cast config option into bool
	to_bool()
	{
		case "${1:-}" in
			1|true|TRUE|yes|YES|on|ON) echo "true";;
			*) echo "false";;
		esac
	}

	# perpare the container for SSH connections
	init_ssh()
	{
		SSH_KEY_PATH=""
		SSH_DIR="/root/.ssh";
		KNOWN_HOSTS="$SSH_DIR/known_hosts"

		# set the base SSH command
		# BatchMode=no is required to allow the passphrase prompt for sshpass.
		SSH_BIN=(ssh -o IdentitiesOnly=yes -o BatchMode=no -o ForwardAgent=no -o ForwardX11=no)

		if [[ -n "$SSH_KEY" ]]; then

			# store the provided SSH key in the deploy container
			SSH_KEY_PATH="$SSH_DIR/id"
			printf '%s\n' "$SSH_KEY" > "$SSH_KEY_PATH"
			chmod 600 "$SSH_KEY_PATH"

			# add the key to the SSH executable
			SSH_BIN+=(-i "$SSH_KEY_PATH")

			# handle password protected keys and password based authentication
			if [[ -n "$PASSWORD" ]]; then
				SSH_BIN=(sshpass -P 'pass' -p "$(printf '%q' "$PASSWORD")" "${SSH_BIN[@]}")
			fi
		fi

		# TOFU (Trust On First Use) by fetching the remote server public keys
		ssh-keyscan -p "$PORT" -T 20 "$SERVER" >> "$KNOWN_HOSTS" 2>/dev/null || true
	}