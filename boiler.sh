#!/bin/bash

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
	cat > "$1".sh << EOL
#!/bin/bash

#### Global Variables ####
DEBUG=0
#### Functions ####
usage()
{
	echo ""
	echo "	Usage for \$0:"
	echo "	Optional Flags:"
	echo "		-h: Display this dialog"
	echo "		-d: Enable Debugging."
	echo "	Required Flags:"
	echo ""
}
print()
{
	local OPTIND
	if [ "\$(uname -s)" == "Darwin" ];then
		Black='\\033[0;30m'        # Black
		Red='\\033[0;31m'          # Red
		Green='\\033[0;32m'        # Green
		Yellow='\\033[0;33m'       # Yellow
		Blue='\\033[0;34m'         # Blue
		Purple='\\033[0;35m'       # Purple
		Cyan='\\033[0;36m'         # Cyan
		White='\\033[0;37m'        # White
		NC='\\033[m'               # Color Reset
	else 
		Black='\\e[0;30m'        # Black
		Red='\\e[0;31m'          # Red
		Green='\\e[0;32m'        # Green
		Yellow='\\e[0;33m'       # Yellow
		Blue='\\e[0;34m'         # Blue
		Purple='\\e[0;35m'       # Purple
		Cyan='\\e[0;36m'         # Cyan
		White='\\e[0;37m'        # White
		NC="\\e[m"               # Color Reset
	fi
	colors=( "\$Red" "\$Green" "\$Gellow" "\$Blue" "\$Purple" "\$Cyan" )
	local DEBUG=0
	FGND=""
	NL=1
	PNL=0
	STRING=" "
	while getopts "f:npKRGYBPCWS:" opt
	do
		case "\$opt" in
			"f")					# Set foreground/text color.
				case "\$OPTARG" in
					"black") FGND="\$Black";;
					"red") FGND="\$Red";;
					"green") FGND="\$Green";;
					"yellow") FGND="\$Yellow";;
					"blue") FGND="\$Blue";;
					"purple") FGND="\$Purple";;
					"cyan") FGND="\$Cyan";;
					"white") FGND="\$White";;
					"*") [ \$DEBUG -eq 1 ] && echo "Unrecognized Arguement: \$OPTARG" ;;
				esac
				;;
			"n") NL=0 ;;	 			# Print with newline.
			"p") ((PNL++)) ;; 			# Prepend with newline.
			"K") FGND="\$Black";;
			"R") FGND="\$Red";;
			"G") FGND="\$Green";;
			"Y") FGND="\$Yellow";;
			"B") FGND="\$Blue";;
			"P") FGND="\$Purple";;
			"C") FGND="\$Cyan";;
			"W") FGND="\$White";;
			"D") local DEBUG=1 ;;
			"S") STRING="\$OPTARG" ;;
			"*") [ \$DEBUG -eq 1 ] && echo "Unknown Arguement: \$opt" ;;
		esac
	done
	if [[ "\$STRING" == " " ]];then
		shift "\$((OPTIND - 1))"
		STRING="\$@" 
	fi
	if [ \$DEBUG -eq 1 ]; then
		echo "FGND: \$FGND"
		echo "NL: \$NL"
		echo "PNL: \$PNL"
		echo "STRING: \$STRING"
	fi
	while [ \$PNL -ne 0 ] 
	do
		printf "\n"
		((PNL--))
	done
	[ ! -z \$FGND ] && STRING="\$FGND\$STRING\$NC"
	printf -- "\$STRING"
	[ \$NL -eq 1 ] && printf "\n"
}

#### Main Run ####
if [ \$# -lt 1 ]; then
	print -R "Missing arguments"
	usage
	exit 1
else
	while getopts "hd" opt
	do
		case "\$opt" in
			"h")
				usage
				;;
			"d")
				DEBUG=1
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
exit 0
EOL
}
test_template()
{
	echo "Testing help dialog"
	bash "$NAME".sh -h
	echo "Testing no arguments"
	bash "$NAME".sh
	echo "Testing debug flag"
	bash "$NAME".sh
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
