#!/usr/bin/env bash

set -euo pipefail

if ! command -v xcrun >/dev/null 2>&1; then
  echo "xcrun is required" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required" >&2
  exit 1
fi

destination="$(
  xcrun simctl list devices available -j \
    | jq -r '
        [
          .devices
          | to_entries[]
          | select(.key | startswith("com.apple.CoreSimulator.SimRuntime.iOS-"))
          | .key as $runtime_key
          | .value[]
          | select(.isAvailable == true)
          | select(.name | startswith("iPhone"))
          | {
              destination: ("platform=iOS Simulator,id=" + .udid),
              name,
              runtime_version: (
                $runtime_key
                | sub("^com.apple.CoreSimulator.SimRuntime.iOS-"; "")
                | split("-")
                | map(tonumber? // 0)
              )
            }
        ]
        | sort_by(.name)
        | sort_by(.runtime_version)
        | reverse
        | .[0].destination // empty
      '
)"

if [ -z "${destination}" ]; then
  echo "No available iPhone simulator found" >&2
  exit 1
fi

echo "${destination}"
