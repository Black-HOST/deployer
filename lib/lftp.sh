#
# ######################################################################################################################
# DEPLOYER 9000 LFTP Common Helper
# 
# DESCRIPTION: 	Builds common arguments for lftp mirror operations.
# 
# VERSION: 		1.0
# DATE: 		2025-08-09 
# AUTHOR: 		Black HOST Ltd.
# ######################################################################################################################
#

lftp_flags() 
{
	# build lftp mirroring flags
	MIRROR_FLAGS=(-R --verbose --parallel="$PARALLEL")
	[[ "$DELETE" == "true" ]]    && MIRROR_FLAGS+=(--delete)
	[[ "$ONLY_NEWER" == "true" ]]&& MIRROR_FLAGS+=(--only-newer)
	[[ "$DRY_RUN" == "true" ]]   && MIRROR_FLAGS+=(--dry-run)

	# generate the exclude argguments
	EXCLUDE_ARGS=()
	for path in "${EXCLUDE_ARR[@]}"; do
	  EXCLUDE_ARGS+=(--exclude-glob "$path")
	done
}