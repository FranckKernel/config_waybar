#!/bin/bash

# Base config path
BASE_PATH="$HOME/.config/waybar/tree_state"

# File to store global toggle state
STATE_FILE="/tmp/waybar_global.state"

# Detect network type
net_type=$(nmcli -t -f DEVICE,TYPE,STATE device status |
	grep ':connected' |
	grep -E 'ethernet|wifi' |
	grep -v '^lo:' |
	cut -d: -f2 |
	sed '/^\s*$/d' |
	sed 's/^[[:space:]]*//; s/[[:space:]]*$//' |
	head -n1)

[[ -z "$net_type" ]] && net_type="ethernet"

# Detect all monitors
monitors=$(hyprctl monitors -j | jq -r '.[].name')

# Kill any running Waybar for this network type
for mon in $monitors; do
	pkill -f "waybar -c $BASE_PATH/$net_type/.*/$mon.jsonc"
done
sleep 0.2

# Read global toggle state
if [[ -f "$STATE_FILE" ]]; then
	state=$(cat "$STATE_FILE")
else
	state="off"
fi

# Determine next state
if [[ "$state" == "on" ]]; then
	next_state="off"
else
	next_state="on"
fi

# If turning on, launch all monitors with correct orientation
if [[ "$next_state" == "on" ]]; then
	for mon in $monitors; do
		# Determine transform
		transform=$(hyprctl monitors -j | jq -r ".[] | select(.name==\"$mon\") | .transform")
		if [[ "$transform" == "1" || "$transform" == "3" ]]; then
			orient="portrait"
		else
			orient="landscape"
		fi

		config="$BASE_PATH/$net_type/$orient/$mon.jsonc"
		if [[ -f "$config" ]]; then
			waybar -c "$config" &
		else
			echo "⚠️ Config missing: $config"
		fi
	done
fi

# Save new global state
echo "$next_state" >"$STATE_FILE"
