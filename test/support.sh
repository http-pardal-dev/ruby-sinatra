# Assertions shared by the end-to-end examples (test/e2e/*.sh).
#
# This file is sourced, never executed: the examples call the helpers below to
# report each example as `ok` or `FAIL`, the same way the documentation format
# of a test runner does. Everything here is POSIX shell; the requests
# themselves stay written out in each example.
#
# Variables are global because POSIX shell has no local: the names below are
# never used by the examples.

suite_examples=0
suite_failures=0
example_name=""
example_failed=0
example_detail=""

# Prints the title of the suite.
suite() {
  printf '\n%s\n' "$1"
}

# Starts a new example. The previous one is reported when this runs.
example() {
  flush_example
  example_name=$1
  example_failed=0
  example_detail=""
  suite_examples=$((suite_examples + 1))
}

# Reports the example that is open, if any.
flush_example() {
  [ -n "$example_name" ] || return 0

  if [ "$example_failed" -eq 0 ]; then
    printf '  ok   %s\n' "$example_name"
  else
    suite_failures=$((suite_failures + 1))
    printf '  FAIL %s\n' "$example_name"
    printf '%s' "$example_detail"
  fi

  example_name=""
}

# Records a failed expectation of the open example.
fail_expectation() {
  example_failed=1
  example_detail="${example_detail}       $1
"
}

# Expects the response to include the text (a status line, a header, JSON...).
# The needle is a literal: characters like `*`, `[` or `{` never become
# patterns, because the match quotes it.
expect_contains() {
  case "$1" in
    *"$2"*) return 0 ;;
  esac

  fail_expectation "expected to include: $2"
}

# The same, ignoring the case (headers such as `Location:`).
expect_contains_ci() {
  lower_response=$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')
  lower_expected=$(printf '%s' "$2" | tr '[:upper:]' '[:lower:]')

  case "$lower_response" in
    *"$lower_expected"*) return 0 ;;
  esac

  fail_expectation "expected to include (ignoring case): $2"
}

# Expects the response NOT to include the text (a password digest, ...).
expect_not_contains() {
  case "$1" in
    *"$2"*) fail_expectation "expected NOT to include: $2" ;;
  esac
}

# Returns the first `"id":123` of the response: the id of the resource that
# was just created. Without an id (a failed creation) the result is empty, and
# the expectations of the next example report the broken request.
extract_id() {
  printf '%s\n' "$1" |
    tr -d '\r' |
    sed -n 's/.*"id":\([0-9][0-9]*\).*/\1/p' |
    sed -n '1p'
}

# Returns a number that does not repeat, for emails and categories that have
# to be unique between runs (the randomness of the system, no Ruby involved).
unique_id() {
  od -An -N4 -tu4 /dev/urandom | tr -d '[:space:]'
}

# Reports the suite and becomes the exit code of the example file: 0 when
# every example passed, 1 when at least one failed. bin/test also reads the
# totals from $E2E_SUMMARY_FILE when it is set.
summary() {
  flush_example

  printf '\n%s examples, %s failures\n' "$suite_examples" "$suite_failures"

  if [ -n "${E2E_SUMMARY_FILE:-}" ]; then
    printf '%s %s\n' "$suite_examples" "$suite_failures" >> "$E2E_SUMMARY_FILE"
  fi

  [ "$suite_failures" -eq 0 ]
}
