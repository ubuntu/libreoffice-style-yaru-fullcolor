#!/bin/bash
#
# This file is free software; you can redistribute it and/or modify it under
# the terms of the GNU Lesser General Public License as published by the Free
# Software Foundation; version 3.

# Shared helpers for scripts that operate on icon theme variants.

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
    local output
    local accent brightness_entry
    local accent_name accent_color brightness_name bg_color txt_color variant_name
    local -a accents brightness

    if ! output=$(read_map_file "$accents_file" 2); then
        return 1
    fi
    mapfile -t accents <<< "$output"

    if ! output=$(read_map_file "$brightness_file" 3); then
        return 1
    fi
    mapfile -t brightness <<< "$output"

    # Each entry contains: variant_name accent_color bg_color txt_color.
    variants=()
    for accent in "${accents[@]}"; do
        read -r accent_name accent_color <<< "$accent"

        for brightness_entry in "${brightness[@]}"; do
            read -r brightness_name bg_color txt_color <<< "$brightness_entry"

            if [[ $brightness_name == default ]]; then
                variant_name=$accent_name
            elif [[ $accent_name == default ]]; then
                variant_name=$brightness_name
            else
                variant_name="${accent_name}_${brightness_name}"
            fi

            variants+=( "$variant_name $accent_color $bg_color $txt_color" )
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
