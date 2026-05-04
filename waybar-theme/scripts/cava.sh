#!/usr/bin/env bash
set -u
bars=(▁ ▂ ▃ ▄ ▅ ▆ ▇ █)
config_file="/tmp/waybar_cava_config"
cat > "$config_file" <<EOF
[general]
bars = 18
framerate = 24
autosens = 1
live-config = 1
mode = scientific
sensitivity = 50
bar_width = 1
bar_spacing = 1
[color]
gradient = 1
gradient_count = 8
gradient_color_1 = '#be95ff'
gradient_color_2 = '#be95ff'
gradient_color_3 = '#3ddbd9'
gradient_color_4 = '#3ddbd9'
gradient_color_5 = '#82cfff'
gradient_color_6 = '#82cfff'
gradient_color_7 = '#ff7eb6'
gradient_color_8 = '#ff7eb6'
[output]
method = raw
channels = mono
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 7
EOF

trap 'kill 0 2>/dev/null || true' EXIT
pause_start=0

convert_to_bars() {
    local line="$1"
    local IFS=';'
    local -a nums
    read -ra nums <<< "$line"
    local out=""
    local n
    for n in "${nums[@]}"; do

        if (( n < 0 || n > 7 )); then
            n=0
        fi
        out+="${bars[n]}"
    done
    printf '%s\n' "$out"
}

# fast check for "only zeros" (silence) using parameter expansion — no regex, no external tools
is_silence() {
    local l="${1//;/}"   # remove semicolons
    # remove all 0 characters; if result is empty => only zeros
    [[ -z "${l//0/}" ]]
}

# Run cava and process its stdout
cava -p "$config_file" 2>/dev/null | while IFS= read -r line || [[ -n "$line" ]]; do
    # silence detection (cheap)
    if is_silence "$line"; then
        if (( pause_start == 0 )); then
            pause_start=$SECONDS
        fi

        # hide after 2 seconds of continuous silence
        if (( SECONDS - pause_start >= 2 )); then
            echo ""
        else
            convert_to_bars "$line"
        fi
        continue
    fi

    # audio returned — reset timer and print bars
    pause_start=0
    convert_to_bars "$line"
done
