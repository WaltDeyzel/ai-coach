#!/bin/bash
# Debug script to see what's happening with the race query

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🔍 Debugging Race Query Response..."
echo ""

# Check what intent was detected
echo "=== USER INTERACTION LOG (last 20 lines) ==="
tail -n 20 "${PROJECT_ROOT}/logs/user_interaction.log"
echo ""

# Check if orchestrator received it
echo "=== ORCHESTRATOR LOG (last 20 lines) ==="
tail -n 20 "${PROJECT_ROOT}/logs/orchestrator.log"
echo ""

# Check training orchestrator
echo "=== TRAINING ORCHESTRATOR LOG (last 20 lines) ==="
tail -n 20 "${PROJECT_ROOT}/logs/training_orchestrator.log"
echo ""

# Check delegation_commands channel
echo "📨 DELEGATION COMMANDS:"
ls -lah "${PROJECT_ROOT}/data_bus/channels/delegation_commands/" | tail -10
echo ""

# Check synthesized_responses channel
echo "📤 SYNTHESIZED RESPONSES:"
ls -lah "${PROJECT_ROOT}/data_bus/channels/synthesized_responses/" | tail -10
echo ""

# Show any actual responses
if ls "${PROJECT_ROOT}/data_bus/channels/synthesized_responses"/*.json 2>/dev/null; then
    echo ""
    echo "Latest synthesized response content:"
    ls -t "${PROJECT_ROOT}/data_bus/channels/synthesized_responses"/*.json 2>/dev/null | head -1 | xargs cat | jq .
fi

echo ""
echo "📝 Check if response file was created:"
ls -lah "${PROJECT_ROOT}/data_bus/channels/user_responses/" | tail -5
