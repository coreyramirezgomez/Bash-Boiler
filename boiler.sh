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
	cat > "$1".sh <<- EOF
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

	#### Main Run ####
	if [ \$# -lt 1 ]; then
		echo "Missing arguments"
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
					echo "Unrecognized Argument: \$opt"
					usage
					exit 1
					;;
			esac
		done
	fi
	if [ \$DEBUG -eq 1 ]; then
		echo "DEBUG: \$DEBUG"
	fi
	exit 0
	EOF
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
