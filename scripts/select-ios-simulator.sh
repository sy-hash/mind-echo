#!/usr/bin/env bash

set -euo pipefail

# Prints a single xcodebuild destination string for an available iPhone simulator,
# for example: platform=iOS Simulator,id=24AB410C-2DE0-4DE3-8BE7-F920A29960E7
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
        def candidates:
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
          ];

        def pick_device($devices):
          $devices
          | sort_by([.runtime_version, .name])
          | last;

        (
          candidates
          | map(select(.name | test("^iPhone [0-9]+$")))
        ) as $plain_iphones
        |
        if ($plain_iphones | length) > 0 then
          pick_device($plain_iphones)
        else
          pick_device(candidates)
        end
        | .destination // empty
      '
)"

if [ -z "${destination}" ]; then
  echo "No available iPhone simulator found" >&2
  exit 1
fi

echo "${destination}"
