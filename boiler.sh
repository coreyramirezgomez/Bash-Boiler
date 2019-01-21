#!/bin/bash
trap catch_exit $?
START=$(date +%s)
if [[ "$(dirname $0)"  == "." ]]; then
	WORK_DIR="$(pwd)"
else
	WORK_DIR="$(dirname $0)"
fi
#### Global Variables ####
DEBUG=0
NAME=""
#### Functions ####
usage()
{
	echo ""
	echo "	Usage for $0:"
	echo "	Optional Flags:"
	echo "		-h: Display this dialog"
	echo "		-d: Enable Debugging."
	echo "	Required Flags:"
	echo "		-n name: Set the name of the script."
	echo ""
}
generate_template()
{
	if [ $# -lt 1 ]; then
		echo "Missing template name"
		exit 1
	fi
	cat > "$1" << EOL
#!/bin/bash
trap catch_exit \$?
START=\$(date +%s)
trap catch_exit INT EXIT
if [[ "\$(dirname \$0)"  == "." ]]; then
	WORK_DIR="\$(pwd)"
else
	WORK_DIR="\$(dirname \$0)"
fi
#### Global Variables ####
DEBUG=0
VERBOSE=""
FORCE_FLAG=0
REQUIRED_BINARIES=( )
OPTIONAL_BINARIES=( )

#### Functions ####
usage()
{
	echo ""
	echo "	Usage for \$0:"
	echo "	Optional Flags:"
	echo "		-h: Display this dialog"
	echo "		-d: Enable Debugging."
	echo "		-f: Answer 'yes'/'y' to all questions. (aka: force)"
	echo "	Required Flags:"
	echo ""
}
getResponse()
{
	[ \$# -lt 1 ] && print -R "Incorrect use of getResponse function." && exit 1
	reply=""
	[ \$FORCE_FLAG -eq 1 ] && reply="y"
	while :
	do
		case "\$reply" in
			"N" | "n")
				return 1
				;;
			"Y" | "y")
				return 0
				;;
			*)
				print -Y -n "\$1 (Y/N): "
				read -n 1 reply
				echo ""
				;;
			esac
	done
}
check_binaries()
{
	if [ \$# -lt 1 ];then
		[ \$DEBUG -eq 1 ] && print -Y "No binary package list to check."
		return 0
	fi
	missing=0
	arr=("\$@")
	for p in "\${arr[@]}"
	do
		if which "\$p"  >&/dev/null; then
			[ \$DEBUG -eq 1 ] && print -G "Found \$p"
		else
			print -Y "Missing binary package: \$p"
			((missing++))
		fi
	done
	return \$missing
}
print()
{
	local OPTIND
	if [ "\$(uname -s)" == "Darwin" ];then
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
	if which cowsay >&/dev/null; then
		local CS="\$(which cowsay)"
	else
		local CS=""
	fi
	if which figlet >&/dev/null; then
		local FIG="\$(which figlet)"
	else
		local FIG=""
	fi
	if which printf >&/dev/null; then
		local PRINTF_E=0
	else
		local PRINTF_E=1
	fi
	local DEBUG=0
	local FGND=""
	local BKGN=""
	local BOLD=0
	local NL=1
	local PNL=0
	local STRING=" "
	local STYLE=""
	local POS=0
	local RAINBOW=0
	local RANDOM_COLOR=0
	local ERR_OUT=0
	local STYLED_LOG=""
	local NOTSTYLED_LOG=""
	while getopts "f:b:IcnpFAKRGYBPCWS:vZzEL:l:" cprint_opt
	do
		case "\$cprint_opt" in
			"f")					# Set foreground/text color.
				case "\$OPTARG" in
					"black") [ \$BOLD -eq 0 ] && FGND="\$Black" || FGND="\$BBlack" ;;
					"red") [ \$BOLD -eq 0 ] && FGND="\$Red" || FGND="\$BRed" ;;
					"green") [ \$BOLD -eq 0 ] && FGND="\$Green" || FGND="\$BGreen" ;;
					"yellow") [ \$BOLD -eq 0 ] && FGND="\$Yellow" || FGND="\$BYellow" ;;
					"blue") [ \$BOLD -eq 0 ] && FGND="\$Blue" || FGND="\$BBlue" ;;
					"purple") [ \$BOLD -eq 0 ] && FGND="\$Purple" || FGND="\$BPurple" ;;
					"cyan") [ \$BOLD -eq 0 ] && FGND="\$Cyan" || FGND="\$BCyan" ;;
					"white") [ \$BOLD -eq 0 ] && FGND="\$White" || FGND="\$BWhite" ;;
					"*") [ \$DEBUG -eq 1 ] && (>&2 echo "Unrecognized Arguement: \$OPTARG") ;;
				esac
				;;
			"b")					# Set background color.
				case "\$OPTARG" in
					"black") BKGN="\$On_Black" ;;
					"red") BKGN="\$On_Red" ;;
					"green") BKGN="\$On_Green" ;;
					"yellow") BKGN="\$On_Yellow" ;;
					"blue") BKGN="\$On_Blue" ;;
					"purple") BKGN="\$On_Purple" ;;
					"cyan") BKGN="\$On_Cyan" ;;
					"white") BKGN="\$On_White" ;;
					"*") [ \$DEBUG -eq 1 ] && (>&2 echo "Unrecognized Arguement: \$OPTARG") ;;
				esac
				;;
			"I") BOLD=1 ;;				# Enable bold text.
			"c")
				local WIDTH=0
				local POS=0
				WIDTH=\$(tput cols)					# Current screen width
				if [ \$WIDTH -le 80 ]; then
					POS=0
				else
					POS=\$((( \$WIDTH - 80 ) / 2 ))		# Middle of screen based on screen width
				fi
				;;				# Center the text in screen.
			"n") NL=0 ;;	 			# Print with newline.
			"p") ((PNL++)) ;; 			# Prepend with newline.
			"F") [ -f "\$FIG" ] && STYLE="\$FIG" ;;
			"A") [ -f "\$CS" ] && STYLE="\$CS" ;;
			"K") [ \$BOLD -eq 0 ] && FGND="\$Black" ||  FGND="\$BBlack" ;;
			"R") [ \$BOLD -eq 0 ] && FGND="\$Red" || FGND="\$BRed" ;;
			"G") [ \$BOLD -eq 0 ] && FGND="\$Green" || FGND="\$BGreen" ;;
			"Y") [ \$BOLD -eq 0 ] && FGND="\$Yellow" || FGND="\$BYellow" ;;
			"B") [ \$BOLD -eq 0 ] && FGND="\$Blue" || FGND="\$BBlue" ;;
			"P") [ \$BOLD -eq 0 ] && FGND="\$Purple" || FGND="\$BPurple" ;;
			"C") [ \$BOLD -eq 0 ] && FGND="\$Cyan" || FGND="\$BCyan" ;;
			"W") [ \$BOLD -eq 0 ] && FGND="\$White" || FGND="\$BWhite";;
			"S") STRING="\$OPTARG" ;;
			"v") DEBUG=1 ;;
			"Z") RANDOM_COLOR=1 ;;
			"z") RAINBOW=1 ;;
			"E") ERR_OUT=1 ;;
			"L") STYLED_LOG="\$OPTARG" ;;
			"l") NOTSTYLED_LOG="\$OPTARG" ;;
			"*") [ \$DEBUG -eq 1 ] && (>&2 echo "Unknown Arguement: \$opt") ;;
		esac
	done
	if [[ "\$STRING" == " " ]];then
		shift "\$((OPTIND - 1))"
		STRING="\$@"
	fi
	if [ \$DEBUG -eq 1 ]; then
		(>&2 echo "FGND: \$FGND")
		(>&2 echo "BKGN: \$BKGN")
		(>&2 echo "BOLD: \$BOLD")
		(>&2 echo "NL: \$NL")
		(>&2 echo "PNL: \$PNL")
		(>&2 echo "POS: \$POS")
		(>&2 echo "STYLE: \$STYLE")
		(>&2 echo "RAINBOW: \$RAINBOW")
		(>&2 echo "PRINTF_E: \$PRINTF_E")
		(>&2 echo "ERR_OUT: \$ERR_OUT")
		(>&2 echo "STRING: \$STRING")
	fi
	#process_prenl()
	while [ \$PNL -ne 0 ]
	do
		if [ \$PRINTF_E -eq 0 ];then
			if [ \$ERR_OUT -eq 1 ]; then
				(>&2 printf "\n")
			else
				printf "\n"
			fi
		else
			if [ \$ERR_OUT -eq 1 ]; then
				(>&2 echo "")
			else
				echo ""
			fi
		fi
		if [ ! -z \${STYLED_LOG} ];then
			echo ""  >> "\$STYLED_LOG"
		fi
		if [ ! -z \${NOTSTYLED_LOG} ]; then
			echo ""  >> "\$NOTSTYLED_LOG"
		fi
		((PNL--))
	done
	#process_string()
	string_proc="\$STRING"
	if [ ! -z \${NOTSTYLED_LOG} ]; then
		echo "\$string_proc"  >> "\$NOTSTYLED_LOG"
	fi
	[ \$RAINBOW -eq 1 ] || [ \$RANDOM_COLOR -eq 1 ] && colors=( "\$Red" "\$Green" "\$Gellow" "\$Blue" "\$Purple" "\$Cyan" )
	if [ \$POS -eq 0 ]; then # non-centered strings
		[ ! -z \$STYLE ] && string_proc="\$(\$STYLE \$string_proc)" # Apply style
		[ ! -z \$BKGN ] && string_proc="\$BKGN\$string_proc" # Apply background color
		if [ \$RAINBOW -eq 0 ]; then # rainbow not invoked, so just apply the foreground
			[ \$RANDOM_COLOR -eq 1 ] && FGND="\${colors[\$RANDOM % \${#colors[@]}]}"
			[ ! -z \$FGND ] && string_proc="\$FGND\$string_proc"
		elif [ -z \$STYLE ]; then # Rainbow invoked. Only apply rainbow if not styled.
			string_proc_r=""
			words=(\$string_proc)
			for c in "\${words[@]}" # Loop through each word separated by spaces
			do
				FGND="\${colors[\$RANDOM % \${#colors[@]}]}"
				[ \$DEBUG -eq 1 ] && (>&2 echo "Random seed: \$RANDOM")
				string_proc_r="\$string_proc_r\$FGND\$c "
			done
			string_proc=\$string_proc_r # Assign final result back to string_proc
		fi
		[ ! -z \$FGND ] || [ ! -z \$BKGN ] && string_proc="\$string_proc\$NC"	# Append color reset if foreground/background is set.
		if [ \$PRINTF_E -eq 0 ]; then # if printf exists
			if [ \$ERR_OUT -eq 1 ]; then # print to stderr
				(>&2 printf -- "\$string_proc")
			else # print to stdout
				printf -- "\$string_proc"
			fi
		else # printf doesn't exist
			[ \$DEBUG -eq 1 ] && (>&2 echo "printf not found, reverting to echo.")
			if [ \$ERR_OUT -eq 1 ]; then # print to stderr
				(>&2 echo "\$string_proc")
			else # print to stdout
				echo "\$string_proc"
			fi
		fi
	else # Centered strings
		if [ \$PRINTF_E -eq 0 ]; then # if printf exists
			if [ \$ERR_OUT -eq 1 ]; then # print to stderr
				(>&2 printf -- "\$FGND\$BKGN%\$POS"s"\$NC" "\$string_proc")
			else # print to stdout
				printf -- "\$FGND\$BKGN%\$POS"s"\$NC" "\$string_proc"
			fi
		else # printf doesn't exist
			[ \$DEBUG -eq 1 ] && (>&2 "printf not found, reverting to echo.")
			if [ \$ERR_OUT -eq 1 ]; then # print to stderr
				(>&2 echo "\$FGND""\$BKGN""\$string_proc""\$NC")
			else # print to stdout
				echo "\$FGND""\$BKGN""\$string_proc""\$NC"
			fi
		fi
	fi
	if [ ! -z \${STYLED_LOG} ];then
		echo -e "\$string_proc"  >> "\$STYLED_LOG"
	fi
	#process_nl()

	if [ \$NL -eq 1 ]; then
		if [ \$ERR_OUT -eq 1 ]; then
			if [ \$PRINTF_E -eq 0 ]; then
				(>&2 printf "\n")
			else
				(>&2 echo "")
			fi
		else
			if [ \$PRINTF_E -eq 0 ];then
				printf "\n"
			else
				echo ""
			fi
		fi
		if [ ! -z \${STYLED_LOG} ];then
			echo ""  >> "\$STYLED_LOG"
		fi
		if [ ! -z \${NOTSTYLED_LOG} ]; then
			echo ""  >> "\$NOTSTYLED_LOG"
		fi
	fi
}
is_root()
{
	if [ "\$(id -u)" -ne "0" ]; then
		print -R "Must run as root. Exiting."
		usage
		exit 1
	fi
}
catch_exit()
{
	code=\$?
	END=\$(date +%s)
	case \$code in
		0) print -G -S "============== Successful exit: \$0 ran for \$(( \$END - \$START ))s ==============";;
		1) print -R -S "============== Fatal exit: \$0 ran for \$(( \$END - \$START ))s ==============";;
		130) print -Y -S "============== User initied exit: \$0 ran for \$(( \$END - \$START ))s ==============";;	
		*) print -Y -S "============== Unknown exit (\$code): \$0 ran for \$(( \$END - \$START ))s ==============";;
	esac
}
#### Main Run ####
if [ \$# -lt 1 ]; then
	print -R "Missing arguments"
	usage
	exit 1
else
	while getopts "hdf" opt
	do
		case "\$opt" in
			"h")
				usage
				;;
			"f")
				FORCE_FLAG=1
				;;
			"d")
				DEBUG=1
				VERBOSE="v"
				;;
			"*")
				print -R "Unrecognized Argument: \$opt"
				usage
				exit 1
				;;
		esac
	done
fi
if [ \$DEBUG -eq 1 ]; then
	print -B "DEBUG: \$DEBUG"
fi
check_binaries "\${REQUIRED_BINARIES[@]}"
[ \$? -gt 0 ] && print -R "Missing \$? binaries." && exit 1
check_binaries "\${OPTIONAL_BINARIES[@]}"
[ \$? -gt 0 ] && print -R "Missing \$? binaries." && exit 1
exit 0
EOL
}
test_template()
{
	echo "$0: Testing help dialog"
	bash "$NAME" -h
	echo "$0: Testing no arguments"
	bash "$NAME"
	echo "$0: Testing debug flag"
	bash "$NAME"
}
catch_exit()
{
	code=$?
	END=$(date +%s)
	case $code in
		0) print -G -S "============== Successful exit: $0 ran for $(( $END - $START ))s ==============";;
		1) print -R -S "============== Fatal exit: $0 ran for $(( $END - $START ))s ==============";;
		130) print -Y -S "============== User initied exit: $0 ran for $(( $END - $START ))s ==============";;
		*) print -Y -S "============== Unknown exit ($code): $0 ran for $(( $END - $START ))s ==============";;
	esac
}
#### Main Run ####
if [ $# -lt 1 ]; then
	echo "Missing arguments"
	usage
	exit 1
else
	while getopts "hdn:" opt
	do
		case "$opt" in
			"h")
				usage
				;;
			"d")
				DEBUG=1
				;;
			"n")
				NAME="$OPTARG"
				;;
			"*")
				echo "Unrecognized Argument: $opt"
				usage
				exit 1
				;;
		esac
	done
fi
if [ $DEBUG -eq 1 ]; then
	echo "DEBUG: $DEBUG"
	echo "NAME: $NAME"
fi
generate_template $NAME
test_template $NAME
exit 0
