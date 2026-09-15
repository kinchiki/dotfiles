#!/usr/bin/env bash

# Source this file from a review wrapper. A standalone REVIEW_TRUST line may
# appear anywhere in the reviewer's output, but exactly one is required.
REVIEW_TRUST_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

review_output_contract() {
  local contract_file="$REVIEW_TRUST_SCRIPT_DIR/../references/reviewer-output-contract.md"

  if [[ ! -r "$contract_file" ]]; then
    echo "UNTRUSTED: missing reviewer output contract: $contract_file" >&2
    return 1
  fi
  cat "$contract_file"
}

report_review_trust_format_error() {
  local review_status="$1"
  local review_file="${2:-}"

  case "$review_status" in
    MISSING)
      echo "UNTRUSTED: reviewer did not provide exactly one standalone REVIEW_TRUST declaration"
      ;;
    AMBIGUOUS)
      echo "UNTRUSTED: reviewer provided multiple REVIEW_TRUST declarations; trust format is ambiguous"
      ;;
    *)
      return 1
      ;;
  esac

  if [[ -n "$review_file" ]]; then
    echo "----- review -----"
    cat "$review_file"
  fi
}

review_retry_notice() {
  echo "UNTRUSTED: do not rerun automatically; ask the user whether to rerun the same reviewer once"
}

review_declared_status() {
  local review_file="$1"

  awk '
    function trim(line) {
      sub(/^[[:space:]]+/, "", line)
      sub(/[[:space:]]+$/, "", line)
      return line
    }

    function normalize_legacy(line) {
      sub(/^[[:space:]#>*`_~+-]+/, "", line)
      sub(/[[:space:]#>*`_~+-]+$/, "", line)
      return line
    }

    BEGIN {
      first_line = ""
      explicit_count = 0
      in_fence = 0
    }

    {
      line = trim($0)

      if (line ~ /^(```|~~~)/) {
        in_fence = !in_fence
        next
      }

      if (line == "") {
        next
      }

      if (first_line == "") {
        first_line = line
      }

      # Only accept an exact standalone declaration outside fenced code. This
      # allows explanatory text before the declaration without treating quoted
      # status tokens in findings as a declaration.
      if (!in_fence && line == "REVIEW_TRUST: TRUSTED") {
        explicit_count++
        explicit_status = "TRUSTED"
      } else if (!in_fence && line == "REVIEW_TRUST: UNTRUSTED") {
        explicit_count++
        explicit_status = "UNTRUSTED"
      }
    }

    END {
      legacy_line = normalize_legacy(first_line)
      legacy_status = ""

      # Keep compatibility with the old leading status format when no modern
      # REVIEW_TRUST declaration is present.
      if (legacy_line ~ /^BLOCKED([[:space:]:：-]|$)/) {
        legacy_status = "BLOCKED"
      } else if (legacy_line ~ /^UNTRUSTED([[:space:]:：-]|$)/) {
        legacy_status = "UNTRUSTED"
      } else if (legacy_line ~ /(レビュー|review|信頼|confidence|reliab|verdict|trust|result|status|判定|結果)/ \
        && legacy_line ~ /(^|[^[:alnum:]_])BLOCKED([^[:alnum:]_]|$)/) {
        legacy_status = "BLOCKED"
      } else if (legacy_line ~ /(レビュー|review|信頼|confidence|reliab|verdict|trust|result|status|判定|結果)/ \
        && legacy_line ~ /(^|[^[:alnum:]_])UNTRUSTED([^[:alnum:]_]|$)/) {
        legacy_status = "UNTRUSTED"
      }

      if (explicit_count > 1 || (explicit_count == 1 && legacy_status != "")) {
        print "AMBIGUOUS"
        exit
      }
      if (explicit_count == 1) {
        print explicit_status
        exit
      }
      if (legacy_status != "") {
        print legacy_status
      } else {
        print "MISSING"
      }
    }
  ' "$review_file"
}
