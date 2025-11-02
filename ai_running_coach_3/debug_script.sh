#!/bin/bash
# Debug Script for AI Running Coach

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== AI Running Coach System Diagnostics ==="
echo ""

echo "1. Agent Status:"
for pid_file in "${PROJECT_ROOT}/pids"/*.pid; do
    [ -f "$pid_file" ] || continue
    agent=$(basename "$pid_file" .pid)
    pid=$(cat "$pid_file")
    if ps -p "$pid" > /dev/null 2>&1; then
        echo "  ✓ $agent (PID: $pid) - RUNNING"
    else
        echo "  ✗ $agent (PID: $pid) - STOPPED"
    fi
done
echo ""

echo "2. Recent Log Activity (last 5 lines per agent):"
for log_file in "${PROJECT_ROOT}/logs"/*.log; do
    [ -f "$log_file" ] || continue
    agent=$(basename "$log_file" .log)
    echo "  --- $agent ---"
    tail -5 "$log_file" | sed 's/^/    /'
done
echo ""

echo "3. Message Queue Status:"
for channel in user_requests delegation_commands synthesized_responses user_responses; do
    channel_dir="${PROJECT_ROOT}/data_bus/channels/${channel}"
    if [ -d "$channel_dir" ]; then
        count=$(ls -1 "$channel_dir"/*.json 2>/dev/null | wc -l)
        echo "  $channel: $count messages"
        if [ $count -gt 0 ]; then
            echo "    Files:"
            ls -1 "$channel_dir"/*.json | head -3 | xargs -n1 basename | sed 's/^/      - /'
        fi
    fi
done
echo ""

echo "4. Gemini CLI Test:"
if command -v gemini &> /dev/null; then
    echo "  Testing Gemini..."
    response=$(gemini "Say OK" 2>&1 | grep -v "cached credentials")
    if echo "$response" | grep -qi "ok"; then
        echo "  ✓ Gemini working"
    else
        echo "  ✗ Gemini issue: $response"
    fi
else
    echo "  ✗ Gemini CLI not found"
fi
echo ""

echo "5. Check for Stuck Processes:"
ps aux | grep -E "orchestrator|user_interaction" | grep -v grep
echo ""

echo "=== Diagnostics Complete ==="
echo ""
echo "To test message flow manually:"
echo "  1. Create test request:"
echo "     echo '{\"request_id\": \"test_123\", \"message\": \"hello\", \"timestamp\": \"$(date +%s)\"}' > data_bus/channels/user_requests/test_123.json"
echo ""
echo "  2. Watch logs in real-time:"
echo "     tail -f logs/user_interaction.log logs/orchestrator.log"
echo ""
echo "  3. Check for response:"
echo "     ls -la data_bus/channels/user_responses/"