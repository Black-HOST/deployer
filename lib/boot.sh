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
	ok() { echo -e "\e[32m[DEPLOYER]\e[0m $*"; }
	log() { echo -e "\e[36m[DEPLOYER]\e[0m $*"; }
	err() { echo -e "\e[31m[DEPLOYER]\e[0m Error: $*" >&2; }
	die() { err "$@"; exit 1; }
	shell_quote() { printf "'%s'" "${1//\'/\'\"\'\"\'}"; }

	# read a config option: <NAME> wins, then INPUT_<NAME> (set by GitHub Actions), then the default
	opt() { local i="INPUT_$1"; printf '%s' "${!1:-${!i:-${2:-}}}"; }

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
		SSH_CMD=(ssh -o IdentitiesOnly=yes -o BatchMode=no -o ForwardAgent=no -o ForwardX11=no -p$PORT)

		if [[ -n "$SSH_KEY" ]]; then

			# store the provided SSH key in the deploy container
			SSH_KEY_PATH="$SSH_DIR/id"
			printf '%s\n' "$SSH_KEY" > "$SSH_KEY_PATH"
			chmod 600 "$SSH_KEY_PATH"

			# add the key to the SSH executable
			SSH_CMD+=(-i "$SSH_KEY_PATH")
		fi

		# handle password protected keys and password based authentication
		if [[ -n "$PASSWORD" ]]; then

			# escape the password for SFPT mode
			[[ $PROTOCOL == sftp ]] && PASSWORD=$(printf '%q' "$PASSWORD")

			# add sshpass when password is provided (indicating there is some pass based auth)
			SSH_CMD=(sshpass -P 'pass' -p "$PASSWORD" "${SSH_CMD[@]}")
		fi

		# TOFU (Trust On First Use) by fetching the remote server public keys
		ssh-keyscan -p "$PORT" -T 20 "$SERVER" >> "$KNOWN_HOSTS" 2>/dev/null || true
	}

	# run a command on the remote server
	run_remote_command()
	{
		local SCRIPT="${1:-}"
		local TYPE="${2:-}"

		# skip if no script is provided
		[[ -z "$SCRIPT" ]] && return

		# pre/post scripts require SSH — not supported for ftp protocol
		[[ "$PROTOCOL" == "ftp" ]] && { log "$TYPE skipped: SSH not available for ftp protocol"; return; }

		# ensure SSH is initialized
		[[ -z "${SSH_CMD:-}" ]] && init_ssh

		log "Running $TYPE script"

		if [[ "$DRY_RUN" == "true" ]]; then
			echo "DRY RUN: '$SCRIPT' on $USERNAME@$SERVER over SSH"
		else
			"${SSH_CMD[@]}" "$USERNAME@$SERVER" "$REMOTE_SHELL $(shell_quote "$SCRIPT")"
		fi
	}

	# define deployment flags
	mirror_flags() 
	{

		# set dynamic flags values based on sync tool
		[[ ${1:-} == rsync ]] \
			&& { EXCLUDE_FLAG=--exclude=;     INCLUDE_FLAG=--include=;     UPDATE_FLAG=--update;     MIRROR_FLAGS=(-az --human-readable --info=STATS2,PROGRESS2); } \
			|| { EXCLUDE_FLAG="--exclude-glob "; INCLUDE_FLAG="--include-glob "; UPDATE_FLAG=--only-newer; MIRROR_FLAGS=(-R --verbose --parallel="$PARALLEL"); }

		# set miroring flafgs 
		[[ "$DELETE" == "true" ]]    && MIRROR_FLAGS+=(--delete)
		[[ "$ONLY_NEWER" == "true" ]]&& MIRROR_FLAGS+=("$UPDATE_FLAG")
		[[ "$DRY_RUN" == "true" ]]   && MIRROR_FLAGS+=(--dry-run)

		# generate the exclude argguments
		EXCLUDE_ARGS=()
		for pattern in "${EXCLUDE_ARR[@]}"; do
		  EXCLUDE_ARGS+=("$EXCLUDE_FLAG$pattern")
		done

		# generate the include arguments (rsync wants them before the excludes, lftp after)
		INCLUDE_ARGS=()
		for pattern in "${INCLUDE_ARR[@]}"; do
		  INCLUDE_ARGS+=("$INCLUDE_FLAG$pattern")
		done
	}

	# delta mode: give every tracked file the time of its last commit, so lftp skips the files that did not change
	delta_mtimes()
	{
		[[ "$DELTA" == "true" ]] || return 0

		# the container runs as root on a checkout owned by the CI user
		git config --global --add safe.directory '*'

		git -C "$LOCAL_DIR" rev-parse --git-dir >/dev/null 2>&1 || { log "delta skipped: $LOCAL_DIR is not a git checkout"; return 0; }

		# CI checkouts are shallow: fetch the missing history, commits and trees only
		if [[ "$(git -C "$LOCAL_DIR" rev-parse --is-shallow-repository)" == "true" ]]; then
			git -C "$LOCAL_DIR" fetch --quiet --no-tags --unshallow --filter=blob:none || { log "delta skipped: unable to fetch the git history"; return 0; }
		fi

		git -C "$LOCAL_DIR" ls-files -z | while IFS= read -r -d '' file; do
		  touch -d "@$(git -C "$LOCAL_DIR" log -1 --format=%ct -- "$file")" "$LOCAL_DIR/$file"
		done
	}