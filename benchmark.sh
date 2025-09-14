#!/bin/bash


SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WRIGGLEKICK="${SCRIPT_DIR}/wrigglekick.sh"
TEST_FILE="${SCRIPT_DIR}/sample.txt"
ITERATIONS=10

echo "=== wrigglekick.sh Performance Benchmark ==="
echo "Test file: ${TEST_FILE}"
echo "Iterations per test: ${ITERATIONS}"
echo "Date: $(date)"
echo

run_benchmark() {
    local operation="$1"
    local description="$2"
    local total_time=0
    
    echo "Testing: ${description}"
    
    for i in $(seq 1 ${ITERATIONS}); do
        start_time=$(date +%s.%N)
        
        case "${operation}" in
            "tree")
                "${WRIGGLEKICK}" "${TEST_FILE}" t > /dev/null 2>&1
                ;;
            "tree_lines")
                "${WRIGGLEKICK}" "${TEST_FILE}" tl > /dev/null 2>&1
                ;;
            "tree_all")
                "${WRIGGLEKICK}" "${TEST_FILE}" tla > /dev/null 2>&1
                ;;
            "focus")
                "${WRIGGLEKICK}" "${TEST_FILE}" f > /dev/null 2>&1
                ;;
        esac
        
        end_time=$(date +%s.%N)
        duration=$(echo "${end_time} - ${start_time}" | bc -l)
        total_time=$(echo "${total_time} + ${duration}" | bc -l)
        
        printf "  Run %2d: %.4f seconds\n" "${i}" "${duration}"
    done
    
    average_time=$(echo "scale=4; ${total_time} / ${ITERATIONS}" | bc -l)
    echo "  Average: ${average_time} seconds"
    echo "  Total:   ${total_time} seconds"
    echo
    
    echo "${average_time}"
}

if ! command -v bc &> /dev/null; then
    echo "Error: bc calculator not found. Installing..."
    sudo apt-get update && sudo apt-get install -y bc
fi

if [[ ! -f "${TEST_FILE}" ]]; then
    echo "Error: Test file ${TEST_FILE} not found"
    exit 1
fi

if [[ ! -f "${WRIGGLEKICK}" ]]; then
    echo "Error: wrigglekick.sh not found at ${WRIGGLEKICK}"
    exit 1
fi

if [[ ! -x "${WRIGGLEKICK}" ]]; then
    chmod +x "${WRIGGLEKICK}"
fi

echo "Running performance benchmarks..."
echo

tree_time=$(run_benchmark "tree" "Tree view (t)")
tree_lines_time=$(run_benchmark "tree_lines" "Tree view with line numbers (tl)")
tree_all_time=$(run_benchmark "tree_all" "Tree view with line numbers and depth (tla)")
focus_time=$(run_benchmark "focus" "Focus view (f)")

echo "=== Summary ==="
echo "Tree view (t):                    ${tree_time}s"
echo "Tree view with lines (tl):        ${tree_lines_time}s"
echo "Tree view with lines+depth (tla): ${tree_all_time}s"
echo "Focus view (f):                   ${focus_time}s"
echo

total_avg=$(echo "scale=4; (${tree_time} + ${tree_lines_time} + ${tree_all_time} + ${focus_time}) / 4" | bc -l)
echo "Overall average time: ${total_avg}s"
