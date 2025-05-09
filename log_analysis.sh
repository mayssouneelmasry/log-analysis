#!/bin/bash

LOG_FILE="access.log"  # Change this to your actual log file name

if [[ ! -f $LOG_FILE ]]; then
  echo "Log file not found: $LOG_FILE"
  exit 1
fi

echo "Analyzing log file: $LOG_FILE"
echo

# 1. Request Counts
total_requests=$(wc -l < "$LOG_FILE")
get_requests=$(grep '"GET' "$LOG_FILE" | wc -l)
post_requests=$(grep '"POST' "$LOG_FILE" | wc -l)

echo "Total requests: $total_requests"
echo "GET requests: $get_requests"
echo "POST requests: $post_requests"
echo

# 2. Unique IPs
unique_ips=$(cut -d' ' -f1 "$LOG_FILE" | sort | uniq)
unique_ip_count=$(echo "$unique_ips" | wc -l)

echo "Unique IPs: $unique_ip_count"
echo "Requests by each IP (GET/POST):"
for ip in $unique_ips; do
    get_count=$(grep "^$ip" "$LOG_FILE" | grep '"GET' | wc -l)
    post_count=$(grep "^$ip" "$LOG_FILE" | grep '"POST' | wc -l)
    echo "$ip: GET=$get_count, POST=$post_count"
done
echo

# 3. Failed Requests (4xx or 5xx)
failures=$(awk '$9 ~ /^[45]/ {count++} END {print count+0}' "$LOG_FILE")
failure_percentage=$(awk -v f="$failures" -v t="$total_requests" 'BEGIN {printf "%.2f", (f/t)*100}')
echo "Failed requests: $failures"
echo "Failure percentage: $failure_percentage%"
echo

# 4. Most Active IP
top_ip=$(cut -d' ' -f1 "$LOG_FILE" | sort | uniq -c | sort -nr | head -n1)
echo "Most active IP: $top_ip"
echo

# 5. Daily Averages
unique_days=$(awk '{print $4}' "$LOG_FILE" | cut -d: -f1 | tr -d '[' | sort | uniq | wc -l)
average_per_day=$(awk -v t="$total_requests" -v d="$unique_days" 'BEGIN {printf "%.2f", t/d}')
echo "Average requests per day: $average_per_day"
echo

# 6. Days with Highest Failures
echo "Failures per day:"
awk '$9 ~ /^[45]/ {gsub(/\[|\]/, "", $4); split($4, a, ":"); print a[1]}' "$LOG_FILE" \
| sort | uniq -c | sort -nr | head
echo

# Additional Analysis

# Requests per Hour
echo "Requests by Hour:"
awk '{split($4, a, ":"); hour=a[2]; print hour}' "$LOG_FILE" \
| sort | uniq -c | sort -n
echo

# Status Code Breakdown
echo "Status code breakdown:"
awk '{print $9}' "$LOG_FILE" | sort | uniq -c | sort -nr
echo

# Most Active User by Method
echo "Most active GET user:"
grep '"GET' "$LOG_FILE" | cut -d' ' -f1 | sort | uniq -c | sort -nr | head -n1
echo "Most active POST user:"
grep '"POST' "$LOG_FILE" | cut -d' ' -f1 | sort | uniq -c | sort -nr | head -n1
echo

# Failure Patterns (by hour and day)
echo "Failure pattern (hours):"
awk '$9 ~ /^[45]/ {split($4, a, ":"); print a[2]}' "$LOG_FILE" \
| sort | uniq -c | sort -nr
echo

echo "Failure pattern (days):"
awk '$9 ~ /^[45]/ {gsub(/\[|\]/, "", $4); split($4, a, ":"); print a[1]}' "$LOG_FILE" \
| sort | uniq -c | sort -nr
echo
