#!/usr/bin/env bash

# Exit on Non-Zero Status
set -e

# Handle steamcmd Command
if [ "$1" = 'steamcmd' ]; then

	# Gosu to Run as steam User
	set -- gosu $STEAM_USER "$@"
fi

# Execute
exec "$@"