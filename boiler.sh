#!/bin/bash
#### Non-Customizable Header ####
trap catch_exit $?
#### ####

#### Custom Header ####
#### ####

#### Non-Customizable Global Variables ####
CLEANUP_FLAG=0
DEBUG=0
FORCE_FLAG=0
LOGGING=0
OPTIONS_TEMPLATE="cdfhlp"
PRETTY_PRINT=1
QUIET=""
START_TIME=$(date +%s)
START_DATE="$(date +%m-%d-%y_%H:%M:%S)"
VERBOSE=""
if [[ "$(dirname $0)"  == "." ]]; then
	WORK_DIR="$(pwd)"
else
	WORK_DIR="$(dirname $0)"
fi
#### ####

#### Customizable Variables ####
BINARIES_OPTIONAL=()
BINARIES_REQUIRED=()
CLEANUP_TARGETS=()
LOG_FILE="$WORK_DIR/""$(basename $0).log"
OPTIONS_CUSTOM=""
#### ####

#### Custom Variables ####
BASH_BOILER_VERSION="2.1"
BINARIES_REQUIRED=( 'beautysh' )
BLOCK_FLAG="####"
BLOCK_END="$BLOCK_FLAG $BLOCK_FLAG"
BLOCK_NAMES=(
	"Non-Customizable Header"
	"Custom Header"
	"Non-Customizable Global Variables"
	"Customizable Variables"
	"Custom Variables"
	"Non-Customizable Functions"
	"Non-Customizable External Template Functions"
	"Customizable Functions"
	"Custom Functions"
	"Customizable Option Parse"
	"Customizable Main Run"
	"Custom Main Run"
)
EXTERNAL_PROJECT_REPOS=(
	"https://github.com/coreyramirezgomez/cprint.git"
)
EXTERNAL_PROJECT_DESTINATION=(
	"$WORK_DIR/cprint"
)
EXTERNAL_PROJECT_INIT_OPTIONS=(
	"bash cprint -E cprint.tmp"
)
EXTERNAL_PROJECT_FILE_TO_IMPORT=(
	"$WORK_DIR/cprint/cprint.tmp"
)
GENERATE=0
NAME=""
OPTIONS_CUSTOM="n:u:"
UPDATE=0
#### ####

#### Non-Customizable Functions ####
backup_file()
{
	case $# in
		0) fail_notice_exit "backup_file: No Arguments provided." 120 ;;
		1)
			backup_target="$1"
			local_print -e -Y -S "backup_file: No backup destination specified."
			backup_dest="$WORK_DIR/$1-backup-$(date +%m-%d-%y_%H:%M:%S)"
			local_print -e -Y -S "backup_file: Using default: $backup_dest"
			;;
		2)
			backup_target="$1"
			backup_dest="$2"
			;;
		*)
			local_print -e -Y -S "backup_file: More that 2 arguments provided: $*"
			local_print -e -Y -S "backup_file: Only using first 2."
			backup_target="$1"
			backup_dest="$2"
			;;
		esac

	if [ ! -f "$backup_target" ]; then
		local_print -R -S "backup_file: No file to backup @ $backup_target"
		return 1
	fi
	if	[ -d "$backup_dest" ]; then
		local_print -R -S "backup_file: Backup destination is a directory: $backup_dest"
		return 1
	fi
	if [ -f "$backup_dest" ]; then
		local_print -Y -S "backup_file: File already exists @ $backup_dest"
		get_response "backup_file: Would you like to backup $backup_dest?"
		[ $? -eq 1 ] && return 1
		backup_file "$backup_dest"
		[ $? -ne 0 ] && return 1
	fi
	cp -f"$VERBOSE" -- "$backup_target" "$backup_dest"
	[ $? -ne 0 ] && fail_notice_exit "backup_file: Backup failure for $backup_target" $?
	local_print -e -B -S "Successfully created backup of $backup_target to $backup_dest"
	return 0
}
catch_exit()
{
	code=$?
	local_print -e -B -S "START DATE: $START_DATE"
	local_print -e -B -S "END DATE: $(date +%m-%d-%y_%H:%M:%S)"
	local_print -e -B -S "$0 ran for  $(( $(date +%s) - $START_TIME ))s"
	case $code in
		# Exit codes from https://www.tldp.org/LDP/abs/html/exitcodes.html
		0) local_print -e -G -S "Successful Exit: $code" ;;
		1) local_print -e -R -S "General Fatal Exit: $code " ;;
		2) local_print -e -R -S "Misuse of shell builtins: $code" ;;
		126) local_print -e -R -S "Command invoked cannot execute: $code" ;;
		127) local_print -e -R -S "Command not found: $code" ;;
		128) local_print -e -R -S "Invalid argument to exit: $code" ;;
		129|13[0-9]|14[0-9]|15[0-9]|16[0-5])local_print -e -R -S "Fatal error signal: $code" ;;
		130) local_print -e -Y -S "Script terminated by Control-C: $code" ;;
		# Custom exit codes
		100) local_print -e -Y -S "Unspecified error: $code" ;;
		101) local_print -e -R -S "Missing required variable or argument: $code" ;;
		120) local_print -e -R -S "Misuse of $0 function: $code" ;;
		*) local_print -e -Y -S "Unknown exit: $code" ;;
	esac
	catch_exit_custom "$?"
	for t in "${CLEANUP_TARGETS[@]}"
	do
		cleanup "$t"
	done
}
check_binaries()
{
	local_print -e -B -S "check_binaries: PATH=$PATH"
	if [ $# -lt 1 ];then
		local_print -e -Y -S "check_binaries: No binary package list to check."
		return 0
	fi
	missing=0
	arr=("$@")
	local_print -e -B -S "check_binaries: Received binary package list: ${arr[*]}"
	for p in "${arr[@]}"
	do
		if which "$p"  >&/dev/null; then
			local_print -e -G -S "check_binaries: Found $p"
		else
			local_print -e -Y -S "check_binaries: Missing binary package: $p"
			((missing++))
		fi
	done
	return $missing
}
cleanup()
{
	[ $# -lt 1 ] && fail_notice_exit "cleanup: No arguments received." 120
	for i in "$@"
	do
		if [ -f "$i" ];then
			local_print -e -Y -S "cleanup: Removing file: $i"
			rm -f"$VERBOSE" "$i"
			return_code=$?
		elif [ -d "$i" ];then
			local_print -e -Y -S "cleanup: Removing directory: $i"
			rm -rf"$VERBOSE" "$i"
			return_code=$?
		else
			local_print -e -R -S "cleanup: $i doesn't exist."
			return_code=0
		fi
	done
	return $return_code
}
fail_notice_exit()
{
	if [ $# -eq 0 ]; then
		desc="Unknown"
		error_code=100
	elif [ $# -eq 1 ]; then
		desc="$1"
		error_code=100
	elif [ $# -gt 2 ]; then
		local_print -e -Y "fail_notice_exit: Received more than 2 required args: $*"
		desc="$1"
		error_code="$2"
	else
		desc="$1"
		error_code="$2"
	fi
	local_print -e -R -S "Failure: $desc"
	exit $error_code
}
get_external_project()
{
	case $# in
		0) fail_notice_exit "get_external_project: No Arguments provided." 120 ;;
		1)
			repo_url="$1"
			local_print -e -Y -S "get_external_project: No destination specified."
			dest="$WORK_DIR/$(echo $repo_url | rev | cut -d \/ -f1 | rev)"
			local_print -e -Y -S "get_external_project: Using default: $dest"
			;;
		2)
			repo_url="$1"
			dest="$2"
			;;
		*)
			local_print -e -Y -S "get_external_project: More that 2 arguments provided: $*"
			local_print -e -Y -S "get_external_project: Only using first 2."
			repo_url="$1"
			dest="$2"
			;;
	esac
	FLAGS=""
	[ ! -z $QUIET ] && FLAGS="-q"
	[ ! -z $VERBOSE ] && FLAGS="-v"
	if [ -d $dest ]; then
		local_print -e -Y -S "get_external_project: Project directory already exists. Attempting pull."
		cd "$dest" || local_print -e -R -S "get_external_project: Can't cd in $dest"
		[ $? -ne 0 ] && return 1
		git pull "$FLAGS"
		return_code=$?
		cd "$WORK_DIR" || local_print -e -R -S "get_external_project: Can't cd in $WORK_DIR"
		[ $? -ne 0 ] && return 1
	else
		git clone "$FLAGS" -- "$repo_url" "$dest"
		return_code=$?
	fi
	return $return_code
}
get_response()
{
	[ $# -lt 1 ] && fail_notice_exit "get_response: Missing question argument." 120
	local_print -e -B -S "get_response: Recieved question: $1"
	reply=""
	[ $FORCE_FLAG -eq 1 ] && reply="y"
	while :
	do
		case "$reply" in
			"N" | "n")
				local_print -e -B -S "get_response: Returning $reply (1) reply."
				return 1
				;;
			"Y" | "y")
				local_print -e -B -S "get_response: Returning $reply (0) reply."
				return 0
				;;
			*)
				[ $DEBUG -ne 1 ] && DEBUG_DISABLED=$DEBUG && DEBUG=$(var_toggle $DEBUG)
				local_print -e -Y -n "$1 (Y/N): "
				read -n 1 reply
				echo ""
				[ ! -z ${DEBUG_DISABLED} ] && DEBUG=$(var_toggle $DEBUG)
				local_print -e -B -S "get_response: Question answered with: $reply"
				;;
		esac
	done
}
init_external_project()
{
	case $# in
		0|1) fail_notice_exit "init_external_project: Not Enough Arguments provided." 120 ;;
		2)
			project_dir="$1"
			init_command="$2"
			;;
		*)
			local_print -e -Y -S "init_external_project: More that 2 arguments provided: $*"
			local_print -e -Y -S "init_external_project: Only using first 2."
			project_dir="$1"
			init_command="$2"
			;;
	esac
	if [ ! -d "$project_dir" ]; then
		local_print -e -R -S "init_external_project: Not a directory: $project_dir"
		return 1
	fi
	cd "$project_dir" || local_print -e -Y -S "init_external_project: Can't cd in $project_dir"
	[ $? -ne 0 ] && return 1
	$init_command
	return_code=$?
	cd "$WORK_DIR" || local_print -e -R -S "init_external_project: Can't cd in $WORK_DIR"
	[ $? -ne 0 ] && return 1
	return $return_code
}
local_print()
{
	if [ $LOGGING -eq 1 ] && [ $DEBUG -eq 1 ];then
		print -l "$LOG_FILE" "$@"
		return 0
	fi
	if [ $LOGGING -eq 1 ] && [ $DEBUG -eq 0 ];then
		print -e -q -l "$LOG_FILE" "$@"
		return 0
	fi
	if [ $LOGGING -eq 0 ] && [ $DEBUG -eq 1 ];then
		print -e "$@"
		return 0
	fi
}
var_state()
{
	case $1 in
		0) echo "OFF" ;;
		1) echo "ON" ;;
		*) echo "Unknown ($1)"
	esac
}
var_toggle()
{
	case $1 in
		[0-1]) echo $(( (($1 + 1 )) % 2 ));;
		*) fail_notice_exit "var_toggle: Can't toggle: $1" 120
	esac
}
usage()
{
	DEBUG_TMP=$DEBUG
	LOGGING_TMP=$LOGGING
	PRETTY_PRINT_TMP=$PRETTY_PRINT
	DEBUG=1
	LOGGING=0
	PRETTY_PRINT=1
	echo ""
	echo "Usage for $0:"
	echo ""
	echo -n "	-c: Toggle cleanup flag. Removes all files/directory variables in CLEANUP_TARGETS array. Default: "
	[ $CLEANUP_FLAG -eq 0 ] && local_print -R "$(var_state $CLEANUP_FLAG)"
	[ $CLEANUP_FLAG -eq 1 ] && local_print -G "$(var_state $CLEANUP_FLAG)"
	echo -n "	-d: Toggle Debugging. Default: "
	[ $DEBUG_TMP -eq 0 ] && local_print -R "$(var_state $DEBUG_TMP)"
	[ $DEBUG_TMP -eq 1 ] && local_print -G "$(var_state $DEBUG_TMP)"
	echo -n "	-f: Answer 'yes'/'y' to all questions. (aka force) Default: "
	[ $FORCE_FLAG -eq 0 ] && local_print -R "$(var_state $FORCE_FLAG)"
	[ $FORCE_FLAG -eq 1 ] && local_print -G "$(var_state $FORCE_FLAG)"
	echo "	-h: Display this dialog"
	echo -n "	-l: Toggle logging to $LOG_FILE. Default: "
	[ $LOGGING_TMP -eq 0 ] && local_print -R "$(var_state $LOGGING_TMP)"
	[ $LOGGING_TMP -eq 1 ] && local_print -G "$(var_state $LOGGING_TMP)"
	echo -n "	-p: Toggle pretty print output (colors). Default: "
	[ $PRETTY_PRINT_TMP -eq 0 ] && local_print -R "$(var_state $PRETTY_PRINT_TMP)"
	[ $PRETTY_PRINT_TMP -eq 1 ] && local_print -G "$(var_state $PRETTY_PRINT_TMP)"
	usage_custom
	echo ""
	DEBUG=$DEBUG_TMP
	LOGGING=$LOGGING_TMP
	PRETTY_PRINT=$PRETTY_PRINT_TMP
	exit 0
}
#### ####

#### Non-Customizable External Template Functions ####
print()
{
	local OPTIND
	if [ "$(uname -s)" == "Darwin" ];then
		Black='\033[0;30m'        # Black
		Red='\033[0;31m'          # Red
		Green='\033[0;32m'        # Green
		Yellow='\033[0;33m'       # Yellow
		Blue='\033[0;34m'         # Blue
		Purple='\033[0;35m'       # Purple
		Cyan='\033[0;36m'         # Cyan
		White='\033[0;37m'        # White
		# Bold
		BBlack='\033[1;30m'       # Black
		BRed='\033[1;31m'         # Red
		BGreen='\033[1;32m'       # Green
		BYellow='\033[1;33m'      # Yellow
		BBlue='\033[1;34m'        # Blue
		BPurple='\033[1;35m'      # Purple
		BCyan='\033[1;36m'        # Cyan
		BWhite='\033[1;37m'       # White
		# Background
		On_Black='\033[40m'       # Black
		On_Red='\033[41m'         # Red
		On_Green='\033[42m'       # Green
		On_Yellow='\033[43m'      # Yellow
		On_Blue='\033[44m'        # Blue
		On_Purple='\033[45m'      # Purple
		On_Cyan='\033[46m'        # Cyan
		On_White='\033[47m'       # White
		NC='\033[m'               # Color Reset
	else
		Black='\e[0;30m'        # Black
		Red='\e[0;31m'          # Red
		Green='\e[0;32m'        # Green
		Yellow='\e[0;33m'       # Yellow
		Blue='\e[0;34m'         # Blue
		Purple='\e[0;35m'       # Purple
		Cyan='\e[0;36m'         # Cyan
		White='\e[0;37m'        # White
		# Bold
		BBlack='\e[1;30m'       # Black
		BRed='\e[1;31m'         # Red
		BGreen='\e[1;32m'       # Green
		BYellow='\e[1;33m'      # Yellow
		BBlue='\e[1;34m'        # Blue
		BPurple='\e[1;35m'      # Purple
		BCyan='\e[1;36m'        # Cyan
		BWhite='\e[1;37m'       # White
		# Background
		On_Black='\e[40m'       # Black
		On_Red='\e[41m'         # Red
		On_Green='\e[42m'       # Green
		On_Yellow='\e[43m'      # Yellow
		On_Blue='\e[44m'        # Blue
		On_Purple='\e[45m'      # Purple
		On_Cyan='\e[46m'        # Cyan
		On_White='\e[47m'       # White
		NC="\e[m"               # Color Reset
	fi
	which cowsay >&/dev/null && local BIN_COW="$(which cowsay)" || local BIN_COW=""
	which figlet >&/dev/null && local BIN_FIG="$(which figlet)" || local BIN_FIG=""
	which printf >&/dev/null && local BIN_PRINTF="$(which printf)" || local BIN_PRINTF=""
	local BOLD=0
	local COLOR_BACKGROUND=""
	local COLOR_FOREGROUND=""
	local DEBUG=0
	local ERR_OUT=0
	local LOG_NOT_STYLED=""
	local LOG_STYLED=""
	local NL=1
	local PNL=0
	local POS=0
	local QUIET=0
	local RAINBOW=0
	local RANDOM_COLOR=0
	local STRING=""
	local STYLE=""
	local VERBOSITY=""
	while getopts "hvTE:enpIAFcb:f:KRGYBPCWqZzL:l:S:" opt
	do
		case "$opt" in
			"h") usage ;;
			"v") VERBOSITY="-v" && DEBUG=1;;
			"e") ERR_OUT=1 ;;
			"n") NL=0 ;;
			"p") ((PNL++)) ;;
			"I") BOLD=1 ;;
			"A") [ -f "$BIN_COW" ] && STYLE="$BIN_COW" ;;
			"F") [ -f "$BIN_FIG" ] && STYLE="$BIN_FIG" ;;
			"c") [ $(tput cols) -le 80 ] && POS=0 || POS=$((( $(tput cols) - 80 ) / 2 )) ;;
			"b")
				case "$OPTARG" in
					"black") COLOR_BACKGROUND="$On_Black" ;;
					"red") COLOR_BACKGROUND="$On_Red" ;;
					"green") COLOR_BACKGROUND="$On_Green" ;;
					"yellow") COLOR_BACKGROUND="$On_Yellow" ;;
					"blue") COLOR_BACKGROUND="$On_Blue" ;;
					"purple") COLOR_BACKGROUND="$On_Purple" ;;
					"cyan") COLOR_BACKGROUND="$On_Cyan" ;;
					"white") COLOR_BACKGROUND="$On_White" ;;
					"*") [ $DEBUG -eq 1 ] && (>&2 echo "Unrecognized Arguement: $OPTARG") ;;
				esac
				;;
			"f")
				case "$OPTARG" in
					"black") [ $BOLD -eq 0 ] && COLOR_FOREGROUND="$Black" || COLOR_FOREGROUND="$BBlack" ;;
					"red") [ $BOLD -eq 0 ] && COLOR_FOREGROUND="$Red" || COLOR_FOREGROUND="$BRed" ;;
					"green") [ $BOLD -eq 0 ] && COLOR_FOREGROUND="$Green" || COLOR_FOREGROUND="$BGreen" ;;
					"yellow") [ $BOLD -eq 0 ] && COLOR_FOREGROUND="$Yellow" || COLOR_FOREGROUND="$BYellow" ;;
					"blue") [ $BOLD -eq 0 ] && COLOR_FOREGROUND="$Blue" || COLOR_FOREGROUND="$BBlue" ;;
					"purple") [ $BOLD -eq 0 ] && COLOR_FOREGROUND="$Purple" || COLOR_FOREGROUND="$BPurple" ;;
					"cyan") [ $BOLD -eq 0 ] && COLOR_FOREGROUND="$Cyan" || COLOR_FOREGROUND="$BCyan" ;;
					"white") [ $BOLD -eq 0 ] && COLOR_FOREGROUND="$White" || COLOR_FOREGROUND="$BWhite" ;;
					"*") [ $DEBUG -eq 1 ] && (>&2 echo "Unrecognized Arguement: $OPTARG") ;;
				esac
				;;
			"K") [ $BOLD -eq 0 ] && COLOR_FOREGROUND="$Black" || COLOR_FOREGROUND="$BBlack" ;;
			"R") [ $BOLD -eq 0 ] && COLOR_FOREGROUND="$Red" || COLOR_FOREGROUND="$BRed" ;;
			"G") [ $BOLD -eq 0 ] && COLOR_FOREGROUND="$Green" || COLOR_FOREGROUND="$BGreen" ;;
			"Y") [ $BOLD -eq 0 ] && COLOR_FOREGROUND="$Yellow" || COLOR_FOREGROUND="$BYellow" ;;
			"B") [ $BOLD -eq 0 ] && COLOR_FOREGROUND="$Blue" || COLOR_FOREGROUND="$BBlue" ;;
			"P") [ $BOLD -eq 0 ] && COLOR_FOREGROUND="$Purple" || COLOR_FOREGROUND="$BPurple" ;;
			"C") [ $BOLD -eq 0 ] && COLOR_FOREGROUND="$Cyan" || COLOR_FOREGROUND="$BCyan" ;;
			"W") [ $BOLD -eq 0 ] && COLOR_FOREGROUND="$White" || COLOR_FOREGROUND="$BWhite";;
			"q") QUIET=1;;
			"Z") RANDOM_COLOR=1 ;;
			"z") RAINBOW=1 ;;
			"L") LOG_STYLED="$OPTARG" ;;
			"l") LOG_NOT_STYLED="$OPTARG" ;;
			"S") STRING="$OPTARG";;
		esac
	done
#debug()
	if [ $DEBUG -eq 1 ]; then
		(>&2 echo "BIN_COW: $BIN_COW")
		(>&2 echo "BIN_FIG: $BIN_FIG")
		(>&2 echo "BIN_PRINTF: $BIN_PRINTF")
		(>&2 echo "BOLD: $BOLD")
		(>&2 echo "COLOR_FOREGROUND: $COLOR_FOREGROUND")
		(>&2 echo "COLOR_BACKGROUND: $COLOR_BACKGROUND")
		(>&2 echo "DEBUG: $DEBUG")
		(>&2 echo "ERR_OUT: $ERR_OUT")
		(>&2 echo "LOG_STYLED: $LOG_STYLED")
		(>&2 echo "LOG_NOT_STYLED: $LOG_NOT_STYLED")
		(>&2 echo "NL: $NL")
		(>&2 echo "PNL: $PNL")
		(>&2 echo "POS: $POS")
		(>&2 echo "QUIET: $QUIET")
		(>&2 echo "STRING: $STRING")
		(>&2 echo "STYLE: $STYLE")
		(>&2 echo "RAINBOW: $RAINBOW")
		(>&2 echo "VERBOSITY: $VERBOSITY")
	fi
	if [[ "$STRING" == "" ]];then
		shift "$((OPTIND - 1))"
		STRING="$*"
	fi
	if [[ "$STRING" != "" ]]; then
#process_prenl()
		while [ $PNL -ne 0 ]
		do
			if [ $QUIET -ne 1 ];then
				if [ -f $BIN_PRINTF ];then
					[ $ERR_OUT -eq 1 ] && (>&2 printf "\n") || printf "\n"
				else
					[ $ERR_OUT -eq 1 ] && (>&2 echo "") || echo ""
				fi
			fi
			[ ! -z ${LOG_STYLED} ] && echo ""  >> "$LOG_STYLED"
			[ ! -z ${LOG_NOT_STYLED} ] && echo ""  >> "$LOG_NOT_STYLED"
			((PNL--))
		done
#process_string()
		string_proc="$STRING"
		[ ! -z ${LOG_NOT_STYLED} ] && echo "$string_proc" >> "$LOG_NOT_STYLED"
		[ $RAINBOW -eq 1 ] || [ $RANDOM_COLOR -eq 1 ] && colors=( "$Red" "$Green" "$Gellow" "$Blue" "$Purple" "$Cyan" )
		if [ $POS -eq 0 ]; then # Non-Centered Strings
			[ ! -z ${STYLE} ] && string_proc="$($STYLE $string_proc)" # Apply style
			[ ! -z ${COLOR_BACKGROUND} ] && string_proc="$COLOR_BACKGROUND$string_proc" # Apply background color
			if [ $RAINBOW -eq 0 ]; then # rainbow not invoked, so just apply the foreground
				[ $RANDOM_COLOR -eq 1 ] && COLOR_FOREGROUND="${colors[$RANDOM % ${#colors[@]}]}"
				[ ! -z ${COLOR_FOREGROUND} ] && string_proc="$COLOR_FOREGROUND$string_proc"
			elif [ -z ${STYLE} ]; then # Rainbow invoked. Only apply rainbow if not styled.
				string_proc_r=""
				words=($string_proc)
				for c in "${words[@]}" # Loop through each word separated by spaces
				do
					COLOR_FOREGROUND="${colors[$RANDOM % ${#colors[@]}]}"
					[ $DEBUG -eq 1 ] && (>&2 echo "Random seed: $RANDOM")
					string_proc_r="$string_proc_r$COLOR_FOREGROUND$c "
				done
				string_proc=$string_proc_r$NC # Assign final result back to string_proc
			fi
			if [ ! -z ${COLOR_FOREGROUND} ] || [ ! -z ${COLOR_BACKGROUND} ]; then
				string_proc="$string_proc$NC" # Append color reset if foreground/background is set.
			fi
			if [ $QUIET -ne 1 ]; then
				if [ -f $BIN_PRINTF ];then
					[ $ERR_OUT -eq 1 ] && (>&2 printf -- "$string_proc") || printf -- "$string_proc"
				else # printf doesn't exist
					[ $ERR_OUT -eq 1 ] && (>&2 echo "$string_proc") || echo "$string_proc"
				fi
			fi
		else # Centered Strings
			if [ $QUIET -ne 1 ];then
				if [ -f $BIN_PRINTF ];then
					[ $ERR_OUT -eq 1 ] && (>&2 printf -- "$COLOR_FOREGROUND$COLOR_BACKGROUND%$POS"s"$NC" "$string_proc") || printf -- "$COLOR_FOREGROUND$COLOR_BACKGROUND%$POS"s"$NC" "$string_proc"
				else # printf doesn't exist
					[ $ERR_OUT -eq 1 ] && (>&2 echo "$COLOR_FOREGROUND""$COLOR_BACKGROUND""$string_proc""$NC") || echo "$COLOR_FOREGROUND""$COLOR_BACKGROUND""$string_proc""$NC"
				fi
			fi
		fi
		[ ! -z ${LOG_STYLED} ] && echo -e "$string_proc" >> "$LOG_STYLED"
#process_nl
		if [ $QUIET -ne 1 ]; then
			if [ $NL -eq 1 ];then
		 		if [ -f $BIN_PRINTF ];then
					[ $ERR_OUT -eq 1 ] && (>&2 printf "\n") || printf "\n"
				else
					[ $ERR_OUT -eq 1 ] && (>&2 echo "") || echo ""
				fi
			fi
		fi
	fi
}
#### ####

#### Customizable Functions ####
catch_exit_custom()
{
	local_print -e -B -S "catch_exit_custom: called with args $*"
}
debug_state()
{
	local_print -e -B -S "debug_state: Current Variable State: "
	local_print -e -B -S "debug_state: WORK_DIR: $WORK_DIR"
	local_print -e -B -S "debug_state: FORCE_FLAG: $(var_state $FORCE_FLAG)"
	local_print -e -B -S "debug_state: DEBUG: $(var_state $DEBUG)"
	local_print -e -B -S "debug_state: VERBOSE: $VERBOSE"
	local_print -e -B -S "debug_state: QUIET: $QUIET"
	local_print -e -B -S "debug_state: PRETTY_PRINT: $PRETTY_PRINT"
	local_print -e -B -S "debug_state: START_DATE: $START_DATE"
	local_print -e -B -S "debug_state: START_TIME: $START_TIME"
	local_print -e -B -S "debug_state: LOG_FILE: $LOG_FILE"
	local_print -e -B -S "debug_state: LOGGING: $(var_state $LOGGING)"
	local_print -e -B -S "debug_state: BINARIES_REQUIRED: ${BINARIES_REQUIRED[*]}"
	local_print -e -B -S "debug_state: BINARIES_OPTIONAL: ${BINARIES_OPTIONAL[*]}"
}
usage_custom()
{
	echo ""
}
#### ####

#### Custom Functions ####
generate_template()
{
	[ $# -lt 1 ] && fail_notice_exit -E -R -S "generate_template: Missing template name." 120
	touch "$1"
	echo "" >> "$1"
	cat > "$1" << EOL
#!/bin/bash
EOL
	for BLOCK_START in "${BLOCK_NAMES[@]}"
	do
		local_print -e -B -S "generate_template: Building $BLOCK_START"
		case "$BLOCK_START" in
			"Non-Customizable Header")
				echo "$BLOCK_FLAG $BLOCK_START $BLOCK_FLAG" >> "$1"
				generate_template_header "$1"
				;;
			"Custom Header" | \
			"Custom Variables" | \
			"Custom Functions" | \
			"Custom Main Run")
				echo "$BLOCK_FLAG $BLOCK_START $BLOCK_FLAG" >> "$1"
				;;
			"Non-Customizable External Template Functions")
				echo "$BLOCK_FLAG $BLOCK_START $BLOCK_FLAG" >> "$1"
				generate_external_functions "$1"
				;;
			"Non-Customizable Option Parse")
				echo "$BLOCK_FLAG $BLOCK_START $BLOCK_FLAG" >> "$1"
				generate_template_option_parse "$1"
				;;
				*)
				echo "$BLOCK_FLAG $BLOCK_START $BLOCK_FLAG" >> "$1"
				START_RECORD=0
				cat "$0" | while read line
				do
					case "$line" in
						"$BLOCK_FLAG $BLOCK_START $BLOCK_FLAG") START_RECORD=1 ;;
						"$BLOCK_END") [ $START_RECORD -eq 1 ] && break ;;
						*) [ $START_RECORD -gt 0 ] && echo "$line" >> "$1" ;;
					esac
				done
				;;
		esac
		local_print -e -B -S "generate_template: Finished $BLOCK_START"
		echo "$BLOCK_END" >> "$1"
		echo "" >> "$1"
	done
	cat >> "$1" << EOL
exit 0
EOL
}
generate_external_functions()
{
	[ $# -lt 1 ] && fail_notice_exit -E -R -S "generate_external_functions: Missing template name." 120
	index=0
	for p in "${EXTERNAL_PROJECT_REPOS[@]}"
	do
		get_external_project "$p" "${EXTERNAL_PROJECT_DESTINATION[$index]}"
		[ $? -ne 0 ] && fail_notice_exit "generate_external_functions: failed to get external project $p" $?
		init_external_project "${EXTERNAL_PROJECT_DESTINATION[$index]}" "${EXTERNAL_PROJECT_INIT_OPTIONS[$index]}"
		[ $? -ne 0 ] && fail_notice_exit "generate_external_functions: failed to setup external project $p with init: ${EXTERNAL_PROJECT_INIT_OPTIONS[$index]}" $?
		cat "${EXTERNAL_PROJECT_FILE_TO_IMPORT[@]}" >> "$1"
		CLEANUP_TARGETS=( ${CLEANUP_TARGETS[@]} "${EXTERNAL_PROJECT_DESTINATION[$index]}" )
	done
}
generate_template_header()
{
	[ $# -lt 1 ] && fail_notice_exit -E -R -S "generate_template_header: Missing template name." 120
	cat >> "$1" << EOL
# BASH_BOILER_VERSION=$BASH_BOILER_VERSION
# Generated with Bash-Boiler on $START_DATE
# Use updater to update this script:
# https://github.com/coreyramirezgomez/Bash-Boiler.git
# Modifying any content between blocks like the following:
# "#### Non-Customizable ... #####"
# ....
# "$BLOCK_END"
# will be overwritten by Bash-Boiler updater function.
trap catch_exit \$?
EOL
}
generate_template_option_parse()
{
	[ $# -lt 1 ] && fail_notice_exit -E -R -S "generate_template_option_parse: Missing template name." 120
	cat >> "$1" << EOL
if [ \$# -lt 1 ]; then
	DEBUG=1
 	local_print -e -R -S "\$0: Missing arguments."
	DEBUG=0
	usage
else
	while getopts "\$OPTIONS_TEMPLATE\$OPTIONS_CUSTOM" opt
	do
		case "\$opt" in
			"c") CLEANUP_FLAG=\$(var_toggle \$CLEANUP_FLAG) ;;
			"d") DEBUG=\$(var_toggle \$DEBUG) ;;
			"f") FORCE_FLAG=\$(var_toggle \$FORCE_FLAG) ;;
			"h") usage ;;
			"l") LOGGING=\$(var_toggle \$LOGGING) ;;
			"p") PRETTY_PRINT=\$(var_toggle \$PRETTY_PRINT) ;;
			"n") GENERATE=1 && NAME="\$OPTARG" ;;
			"u") UPDATE=1 && NAME="\$OPTARG" ;;
		esac
	done
fi
EOL
}
usage_custom()
{
	echo "	-n filename: Filename to generate template at."
	echo "	-u filename: Filename to update with template."
}
update_template()
{
	[ $# -lt 1 ] && fail_notice_exit -E -R -S "generate_template: Missing template name." 120
	current_version="$1"
	new_version="$1-$BASH_BOILER_VERSION"
	echo "" >> "$new_version"
	cat > "$new_version" << EOL
#!/bin/bash
EOL
	for BLOCK_START in "${BLOCK_NAMES[@]}"
	do
		local_print -e -B -S "generate_template: Building $BLOCK_START"
		case "$BLOCK_START" in
			"Non-Customizable Header")
				echo "$BLOCK_FLAG $BLOCK_START $BLOCK_FLAG" >> "$new_version"
				generate_template_header "$new_version"
				;;
			"Customizable Variables" | \
			"Customizable Functions" | \
			"Customizable Option Parse" | \
			"Customizable Main Run"| \
			"Custom Header" | \
			"Custom Variables" | \
			"Custom Functions" | \
			"Custom Main Run")
				echo "$BLOCK_FLAG $BLOCK_START $BLOCK_FLAG" >> "$new_version"
				START_RECORD=0
				cat "$current_version" | while read line
				do
					case "$line" in
						"$BLOCK_FLAG $BLOCK_START $BLOCK_FLAG") START_RECORD=1 ;;
						"$BLOCK_END") [ $START_RECORD -eq 1 ] && break ;;
						*) [ $START_RECORD -gt 0 ] && echo "$line" >> "$new_version" ;;
					esac
				done
				;;
			"Non-Customizable External Template Functions")
				echo "$BLOCK_FLAG $BLOCK_START $BLOCK_FLAG" >> "$new_version"
				generate_external_functions "$new_version"
				;;
			"Non-Customizable Option Parse")
				echo "$BLOCK_FLAG $BLOCK_START $BLOCK_FLAG" >> "$new_version"
				generate_template_option_parse "$new_version"
				;;
			"Non-Customizable Global Variables" | \
			"Non-Customizable Functions")
				echo "$BLOCK_FLAG $BLOCK_START $BLOCK_FLAG" >> "$new_version"
				START_RECORD=0
				cat "$0" | while read line
				do
					case "$line" in
						"$BLOCK_FLAG $BLOCK_START $BLOCK_FLAG") START_RECORD=1 ;;
						"$BLOCK_END") [ $START_RECORD -eq 1 ] && break ;;
						*) [ $START_RECORD -gt 0 ] && echo "$line" >> "$new_version" ;;
					esac
				done
				;;
		esac
		local_print -e -B -S "generate_template: Finished $BLOCK_START"
		echo "$BLOCK_END" >> "$new_version"
		echo "" >> "$new_version"
	done
	cat >> "$new_version" << EOL
exit 0
EOL
	mv -f"$VERBOSE" -- "$new_version" "$current_version"
}
#### ####

#### Customizable Option Parse ####
if [ $# -lt 1 ]; then
	DEBUG=1
 	local_print -e -R -S "$0: Missing arguments."
	DEBUG=0
	usage
else
	while getopts "$OPTIONS_TEMPLATE$OPTIONS_CUSTOM" opt
	do
		case "$opt" in
			"c") CLEANUP_FLAG=$(var_toggle $CLEANUP_FLAG) ;;
			"d") DEBUG=$(var_toggle $DEBUG) ;;
			"f") FORCE_FLAG=$(var_toggle $FORCE_FLAG) ;;
			"h") usage ;;
			"l") LOGGING=$(var_toggle $LOGGING) ;;
			"p") PRETTY_PRINT=$(var_toggle $PRETTY_PRINT) ;;
			"n") GENERATE=1 && NAME="$OPTARG" ;;
			"u") UPDATE=1 && NAME="$OPTARG" ;;
		esac
	done
fi
#### ####

#### Customizable Main Run ####
[ $DEBUG -eq 1 ] && VERBOSE="v"
[ $DEBUG -eq 0 ] && QUIET="q"
if [ $LOGGING -eq 1 ] && [ ! -f "$LOG_FILE" ]; then
	touch "$LOG_FILE"
	local_print -e -B -S "Created Log File: $LOG_FILE @ $START_DATE" -l "$LOG_FILE"
fi
debug_state
check_binaries "${BINARIES_REQUIRED[@]}"
return_code=$?
[ $return_code -ne 0 ] && fail_notice_exit "$0: Missing $return_code required binaries." 101
check_binaries "${BINARIES_OPTIONAL[@]}"
return_code=$?
[ $return_code -ne 0 ] && local_print -e -B -Y "$0: Missing $return_code optional binaries."
#### ####

#### Custom Main Run ####
if [ -f "$NAME" ];then
	get_response "Would you like to backup $NAME"
	if [ $? -eq 0 ]; then
		backup_file "$NAME"
		[ $? -ne 0 ] && fail_notice_exit "$0: Backup of $NAME failed!"
	else
		get_response "$0: Are you sure you want to overwrite $NAME?"
		if [ $? -eq 0 ];then
			local_print -e -Y -S "$0: Will overwrite $NAME."
		elif [ $? -eq 1 ]; then
			local_print -e -G -S "$0: Will not overwrite $NAME. Exiting."
			exit 0
		fi
	fi
fi
if [ $GENERATE -eq 1 ];then
	generate_template "$NAME"
elif [ $UPDATE -eq 1 ];then
	update_template "$NAME"
fi
if [ -f "$NAME" ];then
	beautysh --files "$NAME"
else
	local_print -e -R -S "$0: Failed to beautify because missing file: $NAME."
	exit 1
fi
#### ####

exit 0
