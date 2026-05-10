#!/usr/bin/env -S awk -f
# Find all multiline awk/python scripts in a bash script.
# A multiline awk script starts with: awk [options] ' (quote not closed on same line)
# A multiline python script starts with: python[3] -c ' (quote not closed on same line)
# Both end when a line begins with a closing standalone quote.

/(awk|python3?)[[:space:]].*'/ {
    s = $0
    sub(/.*(awk|python3?)[[:space:]].*'/, "", s)
    if (s ~ /'/) next
    in_awk = 1
    start = NR
    next
}
in_awk && /^[[:space:]]*'/ {
    printf "%s:%d\n", FILENAME, start
    found++
    in_awk = 0
}
END { exit (found > 0) }
