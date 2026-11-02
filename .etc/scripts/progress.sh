#!/usr/bin/env bash
# progress.sh: per-package stats for a Go project: files, lines (code, comments,
# blank), funcs, TODOs and whether each package vets cleanly, plus a bar
# chart of where the code lives.
#
# usage: .scripts/progress.sh [--no-vet]

set -u

root="$(cd "$(dirname "$0")/.." && pwd)"
vet=1
[ "${1:-}" = "--no-vet" ] && vet=0

# ANSI colours
END=$'\033[0m'
BOLD=$'\033[1m'
ITALIC=$'\033[3m'
RED=$'\033[31m'
GREEN=$'\033[32m'
BLUE=$'\033[34m'
CYAN=$'\033[36m'
GRAY=$'\033[90m'
ORANGE=$'\033[38;5;208m'

repeat() { # repeat <string> <count>
	local out="" i
	for ((i = 0; i < $2; i++)); do out+="$1"; done
	printf '%s' "$out"
}

# stats <dir>: prints "files lines code comments blank funcs todos" for the
# .go files directly in dir
stats() {
	find "$1" -maxdepth 1 -name '*.go' -print0 | xargs -0 awk '
		FNR == 1 { files++; block = 0 }
		{ lines++; l = $0; sub(/^[ \t]+/, "", l) }
		/TODO|FIXME|XXX/ { todos++ }
		/^func / { funcs++ }
		block { comments++; if (l ~ /\*\//) block = 0; next }
		l == "" { blank++; next }
		l ~ /^\/\// { comments++; next }
		l ~ /^\/\*/ { comments++; if (l !~ /\*\//) block = 1; next }
		{ code++ }
		END { printf "%d %d %d %d %d %d %d\n", files, lines, code, comments, blank, funcs, todos }
	'
}

# every directory holding .go files, as "module<TAB>package path"
packages=()
while IFS= read -r mod; do
	moddir="$(dirname "$mod")"
	while IFS= read -r dir; do
		pkg="${dir#"$root"}"
		pkg="${pkg#/}"
		packages+=("$moddir"$'\t'"${pkg:-.}")
	done < <(find "$moddir" -name '*.go' -not -path '*/.*' -exec dirname {} \; | sort -u)
done < <(find "$root" -name go.mod -not -path '*/.*' | sort)

if [ ${#packages[@]} -eq 0 ]; then
	echo "${RED}no Go packages found under $root${END}"
	exit 1
fi

headers=(files lines code comments blank funcs todos)
nameWidth=7
for entry in "${packages[@]}"; do
	pkg="${entry#*$'\t'}"
	[ ${#pkg} -gt $nameWidth ] && nameWidth=${#pkg}
done
numWidth=9
statusWidth=6

inner=$((1 + nameWidth + ${#headers[@]} * numWidth + 2 + statusWidth + 1))
bar="$(repeat ━ $inner)"
titleText="$(basename "$root") progress"
title="[ ${CYAN}${titleText}${END}${BOLD} ]"
titleLen=$((${#titleText} + 4))
left=$(((inner - titleLen) / 2))
right=$((inner - titleLen - left))

# badge <colour> <symbol> <word>: a status cell exactly statusWidth wide;
# printf pads by bytes, so the multi-byte symbol is kept out of it
badge() {
	printf '%s' "$1$2 $(printf "%-$((statusWidth - 2))s" "$3")${END}"
}

row() { # row <name> <status> <numbers...>
	local name="$1" status="$2"
	shift 2
	printf '%s' "${BOLD}┃${END} ${CYAN}$(printf "%-${nameWidth}s" "$name")${END}"
	for n in "$@"; do
		printf '%s' "${ORANGE}$(printf "%${numWidth}s" "$n")${END}"
	done
	printf '  %s %s\n' "$status" "${BOLD}┃${END}"
}

printf '%s\n' "${BOLD}┏$(repeat ━ $left)${title}$(repeat ━ $right)┓${END}"

printf '%s' "${BOLD}┃${END} ${BOLD}${BLUE}$(printf "%-${nameWidth}s" package)"
for h in "${headers[@]}"; do printf "%${numWidth}s" "$h"; done
printf '  %-*s%s %s\n' "$statusWidth" "vet" "${END}" "${BOLD}┃${END}"
printf '%s\n' "${BOLD}┣${bar}┫${END}"

totals=(0 0 0 0 0 0 0)
codes=()
failed=0

for entry in "${packages[@]}"; do
	moddir="${entry%%$'\t'*}"
	pkg="${entry#*$'\t'}"
	read -r -a nums <<<"$(stats "$root/$pkg")"

	for i in "${!nums[@]}"; do totals[i]=$((totals[i] + nums[i])); done
	codes+=("${nums[2]}")

	status="$(badge "$GRAY" - skip)"
	if [ $vet -eq 1 ]; then
		absdir="$root/$pkg"
		rel=".${absdir#"$moddir"}"
		if (cd "$moddir" && go vet "$rel" >/dev/null 2>&1); then
			status="$(badge "$GREEN" ✓ ok)"
		else
			status="$(badge "$RED" ✗ fail)"
			failed=$((failed + 1))
		fi
	fi

	row "$pkg" "$status" "${nums[@]}"
done

printf '%s\n' "${BOLD}┣${bar}┫${END}"
if [ $vet -eq 1 ]; then
	if [ $failed -eq 0 ]; then
		total_status="$(badge "$GREEN" ✓ all)"
	else
		total_status="$(badge "$RED" ✗ "$failed")"
	fi
else
	total_status="$(badge "$GRAY" - skip)"
fi
printf '%s' "${BOLD}┃${END} ${BOLD}$(printf "%-${nameWidth}s" total)${END}"
for n in "${totals[@]}"; do printf '%s' "${BOLD}${ORANGE}$(printf "%${numWidth}s" "$n")${END}"; done
printf '  %s %s\n' "$total_status" "${BOLD}┃${END}"
printf '%s\n' "${BOLD}┣${bar}┫${END}"

# share of code lines per package, as bars scaled to the widest package
chartWidth=$((inner - nameWidth - 11))
maxCode=1
for c in "${codes[@]}"; do [ "$c" -gt $maxCode ] && maxCode=$c; done
totalCode=${totals[2]}
[ "$totalCode" -eq 0 ] && totalCode=1

for i in "${!packages[@]}"; do
	pkg="${packages[i]#*$'\t'}"
	c=${codes[i]}
	len=$((c * chartWidth / maxCode))
	[ "$c" -gt 0 ] && [ $len -eq 0 ] && len=1
	pct=$((c * 100 / totalCode))
	printf '%s' "${BOLD}┃${END} ${CYAN}$(printf "%-${nameWidth}s" "$pkg")${END} "
	printf '%s' "${BLUE}$(repeat █ $len)${GRAY}$(repeat ░ $((chartWidth - len)))${END}"
	printf '%s %s\n' "${ORANGE}$(printf '%5s' "$pct%")${END}   " "${BOLD}┃${END}"
done

printf '%s\n' "${BOLD}┗${bar}┛${END}"

ratio=0
[ "${totals[1]}" -gt 0 ] && ratio=$((totals[3] * 100 / totals[1]))
printf '%s\n' "${GRAY}${ITALIC}${#packages[@]} packages · ${ratio}% of lines are comments · run with --no-vet to skip vetting${END}"
