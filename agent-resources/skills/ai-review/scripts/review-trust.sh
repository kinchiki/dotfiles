#!/usr/bin/env bash

# Source this file from a review wrapper. The first nonempty line is the
# reviewer's machine-readable trust declaration.
review_declared_status() {
  local review_file="$1"

  awk '
    function normalize(line) {
      sub(/^[[:space:]#>*`_~+-]+/, "", line)
      sub(/[[:space:]#>*`_~+-]+$/, "", line)
      return line
    }

    BEGIN {
      seen = 0
    }

    /^[[:space:]]*$/ {
      next
    }

    {
      seen = 1
      line = normalize($0)

      if (line ~ /^REVIEW[[:space:]_-]*TRUST[[:space:]:：-]*TRUSTED([^[:alnum:]_]|$)/) {
        print "TRUSTED"
        exit
      }
      if (line ~ /^REVIEW[[:space:]_-]*TRUST[[:space:]:：-]*UNTRUSTED([^[:alnum:]_]|$)/) {
        print "UNTRUSTED"
        exit
      }

      # Keep compatibility with the old leading status format.
      if (line ~ /^BLOCKED([[:space:]:：-]|$)/) {
        print "BLOCKED"
        exit
      }
      if (line ~ /^UNTRUSTED([[:space:]:：-]|$)/) {
        print "UNTRUSTED"
        exit
      }

      # Recognize a natural-language or labeled self-declaration on the first
      # line while avoiding status tokens in later code quotes and findings.
      if (line ~ /(レビュー|review|信頼|confidence|reliab|verdict|trust|result|status|判定|結果)/ \
        && line ~ /(^|[^[:alnum:]_])BLOCKED([^[:alnum:]_]|$)/) {
        print "BLOCKED"
        exit
      }
      if (line ~ /(レビュー|review|信頼|confidence|reliab|verdict|trust|result|status|判定|結果)/ \
        && line ~ /(^|[^[:alnum:]_])UNTRUSTED([^[:alnum:]_]|$)/) {
        print "UNTRUSTED"
        exit
      }

      print "MISSING"
      exit
    }

    END {
      if (!seen) {
        print "MISSING"
      }
    }
  ' "$review_file"
}
