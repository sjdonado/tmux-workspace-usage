#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CURRENT_DIR/helpers.sh"

get_cpu_cores() {
  case "$(uname -s)" in
    Darwin) sysctl -n hw.ncpu ;;
    Linux) nproc ;;
    *) echo 1 ;;
  esac
}

main() {
  local processes=$(get_tmux_option '@workspace_usage_processes' 'tmux')
  local show_mem=$(get_tmux_option '@workspace_usage_mem' 'on')
  local show_cpu=$(get_tmux_option '@workspace_usage_cpu' 'on')
  local status_interval=$(get_tmux_option '@status-interval' 15)
  local interval_delay=$(get_tmux_option '@workspace_usage_interval_delay' 0)

  if (( interval_delay > 0 && interval_delay <= status_interval )); then
    sleep "$interval_delay"
  fi

  local output="N/A"
  local process_list=$(ps aux | grep -E "$processes" | grep -v grep)
  local memory_usage=""
  local cpu_usage=""

  if [ "$show_mem" = "on" ]; then
    memory_usage=$(echo "$process_list" | awk '{print $2, $6}' | sort -u -k1,1 | awk '{sum += $2} END {printf "%.2fMB", sum / 1024}')
  fi

  if [ "$show_cpu" = "on" ]; then
    local cpu_cores=$(get_cpu_cores)
    cpu_usage=$(echo "$process_list" | awk -v cores="$cpu_cores" '{sum += $3} END {printf "%.2f%%", sum / cores}')
  fi

  if [ "$show_mem" = "on" ]; then
    output="$memory_usage"
  fi

  if [ "$show_cpu" = "on" ]; then
    if [ -n "$output" ]; then
      output="$output | $cpu_usage"
    else
      output="$cpu_usage"
    fi
  fi

  echo "$(date '+%Y-%m-%d %H:%M:%S') - Script executed - $output" >> /tmp/tmux-workspace-usage-log.txt
  echo "$output"
}

main
