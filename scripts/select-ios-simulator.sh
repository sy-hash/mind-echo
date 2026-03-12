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

available_devices_json="$(xcrun simctl list devices available -j)"

destination="$(
  printf '%s\n' "$available_devices_json" | jq -r '
    def build_candidate($runtime_key; $device):
      {
        destination: ("platform=iOS Simulator,id=" + $device.udid),
        name: $device.name,
        runtime_version: (
          $runtime_key
          | sub("^com.apple.CoreSimulator.SimRuntime.iOS-"; "")
          | split("-")
          | map(tonumber? // 0)
        ),
        device_number: (
          if ($device.name | test("^iPhone [0-9]+$")) then
            ($device.name | capture("^iPhone (?<n>[0-9]+)$").n | tonumber)
          else
            0
          end
        )
      };

    [
      .devices
      | to_entries[]
      | select(.key | startswith("com.apple.CoreSimulator.SimRuntime.iOS-"))
      | .key as $runtime_key
      | .value[]
      | select(.isAvailable == true)
      | select(.name | startswith("iPhone"))
      | build_candidate($runtime_key; .)
    ] as $all_candidates
    |
    [
      $all_candidates[]
      | select(.name | test("^iPhone [0-9]+$"))
    ] as $standard_candidates
    |
    if ($standard_candidates | length) > 0 then
      $standard_candidates
    else
      $all_candidates
    end
    | sort_by([.runtime_version, .device_number, .name])
    | last
    | .destination // empty
  '
)"

if [ -z "${destination}" ]; then
  echo "No available iPhone simulator found" >&2
  exit 1
fi

echo "${destination}"
