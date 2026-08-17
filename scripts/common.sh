#!/bin/bash
#
# This file is free software; you can redistribute it and/or modify it under
# the terms of the GNU Lesser General Public License as published by the Free
# Software Foundation; version 3.

# Shared helpers for scripts that operate on icon theme variants.

# Print the foreground color nearest to its original Oklab lightness that
# reaches the requested WCAG contrast against the background.
#
# Usage: optimize_contrast BG FG [LARGE_TEXT [TARGET]]
# BG and FG may be three- or six-digit hex colors, with or without a leading
# '#'. The result follows FG's leading-'#' convention. LARGE_TEXT is false by
# default; when it is true, the default target is reduced from 4.5 to 3.
function optimize_contrast() {
    local background=${1-}
    local foreground=${2-}
    local large_text=${3:-false}
    local target=${4:-4.5}
    local output_prefix=
    local output

    if (( $# < 2 || $# > 4 )); then
        printf 'Usage: optimize_contrast BG FG [LARGE_TEXT [TARGET]]\n' >&2
        return 2
    fi

    [[ $foreground == \#* ]] && output_prefix='#'
    background=${background#\#}
    foreground=${foreground#\#}

    if [[ $background =~ ^[[:xdigit:]]{3}$ ]]; then
        background=${background:0:1}${background:0:1}${background:1:1}${background:1:1}${background:2:1}${background:2:1}
    fi
    if [[ $foreground =~ ^[[:xdigit:]]{3}$ ]]; then
        foreground=${foreground:0:1}${foreground:0:1}${foreground:1:1}${foreground:1:1}${foreground:2:1}${foreground:2:1}
    fi
    if [[ ! $background =~ ^[[:xdigit:]]{6}$ || ! $foreground =~ ^[[:xdigit:]]{6}$ ]]; then
        printf 'optimize_contrast: colors must be 3- or 6-digit hexadecimal values\n' >&2
        return 2
    fi
    case $large_text in
        true|false) ;;
        *)
            printf 'optimize_contrast: LARGE_TEXT must be true or false\n' >&2
            return 2
            ;;
    esac
    if [[ ! $target =~ ^([0-9]+([.][0-9]*)?|[.][0-9]+)$ ]]; then
        printf 'optimize_contrast: TARGET must be a positive number\n' >&2
        return 2
    fi

    output=$(awk -v bg="$background" -v fg="$foreground" \
        -v large_text="$large_text" -v target="$target" '
        function min(a, b) { return a < b ? a : b }
        function max(a, b) { return a > b ? a : b }
        function abs(a) { return a < 0 ? -a : a }
        function hex_value(value,    digits, result, i) {
            digits = "0123456789abcdef"
            value = tolower(value)
            result = 0
            for (i = 1; i <= length(value); i++)
                result = result * 16 + index(digits, substr(value, i, 1)) - 1
            return result
        }
        function channel_to_linear(value) {
            value /= 255
            return value < 0.03928 ? value / 12.92 : ((value + 0.055) / 1.055) ^ 2.4
        }
        function linear_to_channel(value) {
            value = max(0, min(1, value))
            value = value <= 0.0031308 ? value * 12.92 : 1.055 * value ^ (1 / 2.4) - 0.055
            return int(value * 255 + 0.5)
        }
        function set_rgb(hex, values) {
            values[1] = hex_value(substr(hex, 1, 2))
            values[2] = hex_value(substr(hex, 3, 2))
            values[3] = hex_value(substr(hex, 5, 2))
        }
        function luminance(rgb) {
            return 0.2126 * channel_to_linear(rgb[1]) + \
                   0.7152 * channel_to_linear(rgb[2]) + \
                   0.0722 * channel_to_linear(rgb[3])
        }
        function contrast(first, second,    first_l, second_l) {
            first_l = luminance(first)
            second_l = luminance(second)
            return (max(first_l, second_l) + 0.05) / (min(first_l, second_l) + 0.05)
        }
        function rgb_to_oklab(rgb, lab,    r, g, b, l, m, s, lc, mc, sc) {
            r = channel_to_linear(rgb[1]); g = channel_to_linear(rgb[2]); b = channel_to_linear(rgb[3])
            l = 0.4122214708*r + 0.5363325363*g + 0.0514459929*b
            m = 0.2119034982*r + 0.6806995451*g + 0.1073969566*b
            s = 0.0883024619*r + 0.2817188376*g + 0.6299787005*b
            lc = l ^ (1/3); mc = m ^ (1/3); sc = s ^ (1/3)
            lab[1] = 0.2104542553*lc + 0.7936177850*mc - 0.0040720468*sc
            lab[2] = 1.9779984951*lc - 2.4285922050*mc + 0.4505937099*sc
            lab[3] = 0.0259040371*lc + 0.7827717662*mc - 0.8086757660*sc
        }
        function oklab_to_rgb(L, a, b, rgb,    lc, mc, sc, l, m, s, r, g, blue) {
            lc = L + 0.3963377774*a + 0.2158037573*b
            mc = L - 0.1055613458*a - 0.0638541728*b
            sc = L - 0.0894841775*a - 1.2914855480*b
            l = lc*lc*lc; m = mc*mc*mc; s = sc*sc*sc
            r =  4.0767416621*l - 3.3077115913*m + 0.2309699292*s
            g = -1.2684380046*l + 2.6097574011*m - 0.3413193965*s
            blue = -0.0041960863*l - 0.7034186147*m + 1.7076147010*s
            rgb[1] = linear_to_channel(r)
            rgb[2] = linear_to_channel(g)
            rgb[3] = linear_to_channel(blue)
        }
        BEGIN {
            if (target <= 0) {
                print "optimize_contrast: TARGET must be greater than zero" > "/dev/stderr"
                exit 2
            }
            if (large_text == "true" && target == 4.5) target = 3

            set_rgb(bg, background)
            set_rgb(fg, original)
            foreground[1] = original[1]; foreground[2] = original[2]; foreground[3] = original[3]
            rgb_to_oklab(original, original_lab)
            achromatic = original[1] == original[2] && original[2] == original[3]
            a = achromatic ? 0 : original_lab[2]
            b = achromatic ? 0 : original_lab[3]
            lighten = luminance(original) > luminance(background)
            low = lighten ? original_lab[1] : 0
            high = lighten ? 1 : original_lab[1]

            oklab_to_rgb(lighten ? high : low, a, b, boundary)
            if (contrast(background, boundary) < target) {
                printf "optimize_contrast: cannot reach contrast target %g for %s on %s\n", \
                       target, fg, bg > "/dev/stderr"
                exit 1
            }

            for (i = 0; i < 24; i++) {
                middle = (low + high) / 2
                oklab_to_rgb(middle, a, b, candidate)
                if (contrast(background, candidate) >= target) {
                    if (lighten) high = middle; else low = middle
                    foreground[1] = candidate[1]; foreground[2] = candidate[2]; foreground[3] = candidate[3]
                } else {
                    if (lighten) low = middle; else high = middle
                }
            }

            rgb_to_oklab(foreground, current_lab)
            step = original_lab[1] > current_lab[1] ? 0.001 : -0.001
            try_l = current_lab[1] + step
            while (abs(current_lab[1] - original_lab[1]) > 1e-12 && \
                   !((step > 0 && try_l > original_lab[1]) || (step < 0 && try_l < original_lab[1]))) {
                oklab_to_rgb(try_l, a, b, candidate)
                if (contrast(background, candidate) < target) break
                foreground[1] = candidate[1]; foreground[2] = candidate[2]; foreground[3] = candidate[3]
                try_l += step
            }

            if (!achromatic) {
                oklab_to_rgb(original_lab[1], a, b, initial)
                do {
                    changed = 0
                    for (channel = 1; channel <= 3; channel++) {
                        if (foreground[channel] == initial[channel]) continue
                        saved = foreground[channel]
                        foreground[channel] += initial[channel] > foreground[channel] ? 1 : -1
                        if (contrast(background, foreground) >= target) changed = 1
                        else foreground[channel] = saved
                    }
                } while (changed)
            }

            printf "%02x%02x%02x\n", foreground[1], foreground[2], foreground[3]
        }
    ') || return $?

    printf '%s%s\n' "$output_prefix" "$output"
}

function read_map_file() {
    local map_file=$1
    local expected_fields=$2
    local line
    local -a fields
    local line_number=0

    while IFS= read -r line; do
        line_number=$((line_number + 1))
        [[ -z ${line//[[:space:]]/} || $line =~ ^[[:space:]]*# ]] && continue

        read -r -a fields <<< "$line"
        if (( ${#fields[@]} != expected_fields )); then
            printf 'Error in "%s": %s (line %d)\n' \
                "$map_file" "$line" "$line_number" >&2
            return 1
        fi
        printf '%s\n' "$line"
    done < "$map_file"
}

function load_variants() {
    local accents_file=${1:-src/accents.txt}
    local brightness_file=${2:-src/brightness.txt}
    local dummy_colors_file=${3:-src/dummy-colors.txt}
    local output
    local accent brightness_entry dummy_color mapped_color
    local accent_name accent_color optimized_accent_color
    local brightness_name bg_color txt_color contrast_target variant_name
    local optimized_dummy_color cache_key
    local index
    local -a accents brightness dummy_colors variant_replacements
    local -A seen_dummy_colors special_roles optimized_dummy_colors

    if ! output=$(read_map_file "$accents_file" 2); then
        return 1
    fi
    mapfile -t accents <<< "$output"

    if ! output=$(read_map_file "$brightness_file" 4); then
        return 1
    fi
    mapfile -t brightness <<< "$output"

    if ! output=$(read_map_file "$dummy_colors_file" 2); then
        return 1
    fi
    mapfile -t dummy_colors <<< "$output"

    if (( ${#dummy_colors[@]} < 3 )); then
        printf 'Error in "%s": expected accent, bg_color, and txt_color mappings first\n' \
            "$dummy_colors_file" >&2
        return 1
    fi

    # Scour emits lowercase shorthand whenever a six-digit color can be
    # compressed. Normalize dummy colors to the form present in its output.
    for index in "${!dummy_colors[@]}"; do
        read -r dummy_color mapped_color <<< "${dummy_colors[$index]}"
        dummy_color=${dummy_color#\#}
        dummy_color=${dummy_color,,}
        if [[ $dummy_color =~ ^([[:xdigit:]])\1([[:xdigit:]])\2([[:xdigit:]])\3$ ]]; then
            dummy_color=${BASH_REMATCH[1]}${BASH_REMATCH[2]}${BASH_REMATCH[3]}
        elif [[ ! $dummy_color =~ ^([[:xdigit:]]{3}|[[:xdigit:]]{6})$ ]]; then
            printf 'Error in "%s": invalid dummy color "%s"\n' \
                "$dummy_colors_file" "$dummy_color" >&2
            return 1
        fi
        if [[ -n ${seen_dummy_colors[$dummy_color]+x} ]]; then
            printf 'Error in "%s": duplicate dummy color "%s"\n' \
                "$dummy_colors_file" "$dummy_color" >&2
            return 1
        fi
        seen_dummy_colors["$dummy_color"]=1
        dummy_colors[$index]="$dummy_color $mapped_color"

        if (( index < 3 )); then
            case $mapped_color in
                accent) accent_dummy_color=$dummy_color ;;
                bg_color) bg_dummy_color=$dummy_color ;;
                txt_color) txt_dummy_color=$dummy_color ;;
                *)
                    printf 'Error in "%s": the first three mappings must target accent, bg_color, or txt_color\n' \
                        "$dummy_colors_file" >&2
                    return 1
                    ;;
            esac
            if [[ -n ${special_roles[$mapped_color]+x} ]]; then
                printf 'Error in "%s": duplicate special mapping "%s"\n' \
                    "$dummy_colors_file" "$mapped_color" >&2
                return 1
            fi
            special_roles["$mapped_color"]=1
        fi
    done

    if [[ -z ${special_roles[accent]+x} || -z ${special_roles[bg_color]+x} ||
          -z ${special_roles[txt_color]+x} ]]; then
        printf 'Error in "%s": the first three mappings must configure accent, bg_color, and txt_color\n' \
            "$dummy_colors_file" >&2
        return 1
    fi

    # Each entry begins with variant_name, accent_color, bg_color, and
    # txt_color, followed by dummy/replacement color pairs used by rendering.
    variants=()
    for accent in "${accents[@]}"; do
        read -r accent_name accent_color <<< "$accent"

        for brightness_entry in "${brightness[@]}"; do
            read -r brightness_name bg_color txt_color contrast_target <<< "$brightness_entry"

            if ! optimized_accent_color=$(
                optimize_contrast "$bg_color" "$accent_color" false "$contrast_target"
            ); then
                printf 'Error: cannot optimize accent "%s" for brightness "%s"\n' \
                    "$accent_name" "$brightness_name" >&2
                return 1
            fi

            if [[ $brightness_name == default ]]; then
                variant_name=$accent_name
            elif [[ $accent_name == default ]]; then
                variant_name=$brightness_name
            else
                variant_name="${accent_name}_${brightness_name}"
            fi

            variant_replacements=(
                "$accent_dummy_color" "$optimized_accent_color"
                "$bg_dummy_color" "$bg_color"
                "$txt_dummy_color" "$txt_color"
            )
            for (( index = 3; index < ${#dummy_colors[@]}; index++ )); do
                read -r dummy_color mapped_color <<< "${dummy_colors[$index]}"
                cache_key="$brightness_name:$mapped_color"
                optimized_dummy_color=${optimized_dummy_colors[$cache_key]-}
                if [[ -z $optimized_dummy_color ]]; then
                    if ! optimized_dummy_color=$(
                        optimize_contrast "$bg_color" "$mapped_color" false "$contrast_target"
                    ); then
                        printf 'Error: cannot optimize dummy color "%s" for brightness "%s"\n' \
                            "$dummy_color" "$brightness_name" >&2
                        return 1
                    fi
                    optimized_dummy_colors["$cache_key"]=$optimized_dummy_color
                fi
                variant_replacements+=( "$dummy_color" "$optimized_dummy_color" )
            done

            variants+=(
                "$variant_name $optimized_accent_color $bg_color $txt_color ${variant_replacements[*]}"
            )
        done
    done
}

function filter_variants() {
    (( $# > 0 )) || return 0

    local requested_variant variant variant_name
    local variant_found=0
    local -a filtered_variants=()
    local -a unknown_variants=()
    local -A selected_variant_names=()

    for requested_variant in "$@"; do
        variant_found=0
        for variant in "${variants[@]}"; do
            read -r variant_name _ <<< "$variant"
            if [[ $variant_name == "$requested_variant" ]]; then
                selected_variant_names["$variant_name"]=1
                variant_found=1
                break
            fi
        done
        if (( variant_found == 0 )); then
            unknown_variants+=( "$requested_variant" )
        fi
    done

    if (( ${#unknown_variants[@]} > 0 )); then
        printf 'Error: unknown variant(s):' >&2
        printf ' %s' "${unknown_variants[@]}" >&2
        printf '\nAvailable variants:' >&2
        for variant in "${variants[@]}"; do
            read -r variant_name _ <<< "$variant"
            printf ' %s' "$variant_name" >&2
        done
        printf '\n' >&2
        return 1
    fi

    for variant in "${variants[@]}"; do
        read -r variant_name _ <<< "$variant"
        if [[ -n ${selected_variant_names[$variant_name]+x} ]]; then
            filtered_variants+=( "$variant" )
        fi
    done

    variants=( "${filtered_variants[@]}" )
}

function get_theme_name() {
    if [[ $1 == default ]]; then
        printf '%s\n' images_yaru
    else
        printf 'images_yaru_%s\n' "$1"
    fi
}
