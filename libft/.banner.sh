#!/usr/bin/env bash
# ============================================================
#  .banner.sh — auto-display project stats when you cd into
#  your libft directory. Drop this file in the libft root.
# ============================================================

# --- colors ---
RESET=$'\033[0m'
BOLD=$'\033[1m'
DIM=$'\033[2m'
CYAN=$'\033[36m'
GREEN=$'\033[32m'
YELLOW=$'\033[33m'
RED=$'\033[31m'
MAGENTA=$'\033[35m'
BLUE=$'\033[34m'
GREY=$'\033[90m'

# --- helpers ---
count_c() { find "$1" -name "*.c" 2>/dev/null | wc -l | tr -d ' '; }
exists_dir() { [ -d "$1" ] && [ -n "$(find "$1" -name '*.c' 2>/dev/null)" ]; }

# --- gather stats ---
MANDATORY=$(count_c "mandatory")
BONUS=$(count_c "bonus")
EXTRA=$(count_c "extra")

GNL_OK="no"
exists_dir "get_next_line" && GNL_OK="yes"

PRINTF_OK="no"
exists_dir "ft_printf" && PRINTF_OK="yes"

TOTAL_FILES=$(find . -name "*.c" 2>/dev/null | wc -l | tr -d ' ')
TOTAL_LOC=$(find . \( -name "*.c" -o -name "*.h" \) -exec cat {} + 2>/dev/null | wc -l | tr -d ' ')

# norminette check (only if installed)
if command -v norminette >/dev/null 2>&1; then
    NORM_ERR=$(norminette . 2>/dev/null | grep -c "Error")
    if [ "$NORM_ERR" -eq 0 ]; then
        NORM_STATUS="${GREEN}clean${RESET}"
    else
        NORM_STATUS="${RED}${NORM_ERR} error(s)${RESET}"
    fi
else
    NORM_STATUS="${GREY}norminette not installed${RESET}"
fi

# git info (only if repo)
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    LAST_COMMIT=$(git log -1 --pretty=%s 2>/dev/null)
    DIRTY=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    if [ "$DIRTY" -eq 0 ]; then
        GIT_STATE="${GREEN}clean${RESET}"
    else
        GIT_STATE="${YELLOW}${DIRTY} uncommitted change(s)${RESET}"
    fi
else
    BRANCH="-"
    LAST_COMMIT="-"
    GIT_STATE="${GREY}not a git repo${RESET}"
fi

status_tag() {
    if [ "$1" = "yes" ]; then echo -e "${GREEN}✔${RESET}"; else echo -e "${GREY}✘${RESET}"; fi
}

# --- banner ---
echo -e "${CYAN}${BOLD}"
cat << "EOF"
 _     ___ ____  _____ _____
| |   |_ _| __ )|  ___|_   _|
| |    | ||  _ \| |_    | |
| |___ | || |_) |  _|   | |
|_____|___|____/|_|     |_|
EOF
echo -e "${RESET}${DIM}  advanced libft — project status${RESET}"
echo -e "${GREY}────────────────────────────────────────────${RESET}"

printf "  ${BOLD}%-14s${RESET} %s\n" "Mandatory:"  "${MANDATORY} functions"
printf "  ${BOLD}%-14s${RESET} %s\n" "Bonus:"      "${BONUS} functions"
printf "  ${BOLD}%-14s${RESET} %s\n" "Extra utils:" "${EXTRA} functions"
printf "  ${BOLD}%-14s${RESET} %s\n" "get_next_line:" "$(status_tag $GNL_OK)"
printf "  ${BOLD}%-14s${RESET} %s\n" "ft_printf:"   "$(status_tag $PRINTF_OK)"

echo -e "${GREY}────────────────────────────────────────────${RESET}"
printf "  ${BOLD}%-14s${RESET} %s\n" "Total .c files:" "${TOTAL_FILES}"
printf "  ${BOLD}%-14s${RESET} %s\n" "Total LOC:"   "${TOTAL_LOC}"
printf "  ${BOLD}%-14s${RESET} %s\n" "Norm:"        "$(echo -e $NORM_STATUS)"

echo -e "${GREY}────────────────────────────────────────────${RESET}"
printf "  ${BOLD}%-14s${RESET} %s\n" "Branch:"      "${MAGENTA}${BRANCH}${RESET}"
printf "  ${BOLD}%-14s${RESET} %s\n" "Last commit:" "${BLUE}${LAST_COMMIT}${RESET}"
printf "  ${BOLD}%-14s${RESET} %s\n" "Git state:"   "$(echo -e $GIT_STATE)"
echo ""
