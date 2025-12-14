#!/bin/bash
# Coverage collection script for genui_anthropic
#
# Usage:
#   ./tool/coverage.sh          # Run tests with coverage
#   ./tool/coverage.sh --html   # Generate HTML report
#   ./tool/coverage.sh --open   # Generate and open HTML report
#
# Prerequisites:
#   - lcov (for HTML report): brew install lcov
#
# Output:
#   - coverage/lcov.info        # Raw coverage data
#   - coverage/html/index.html  # HTML report (if --html or --open)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

echo "Running tests with coverage..."
flutter test --coverage

# Check if lcov.info was generated
if [ ! -f "coverage/lcov.info" ]; then
    echo "Error: coverage/lcov.info not generated"
    exit 1
fi

# Calculate coverage percentage
TOTAL_LINES=$(grep -E "^LF:" coverage/lcov.info | cut -d: -f2 | awk '{sum+=$1} END {print sum}')
COVERED_LINES=$(grep -E "^LH:" coverage/lcov.info | cut -d: -f2 | awk '{sum+=$1} END {print sum}')

if [ "$TOTAL_LINES" -gt 0 ]; then
    COVERAGE=$(echo "scale=2; $COVERED_LINES * 100 / $TOTAL_LINES" | bc)
    echo ""
    echo "====================================="
    echo "Coverage: $COVERAGE% ($COVERED_LINES/$TOTAL_LINES lines)"
    echo "====================================="
fi

# Generate HTML report if requested
if [[ "$1" == "--html" || "$1" == "--open" ]]; then
    if command -v genhtml &> /dev/null; then
        echo ""
        echo "Generating HTML coverage report..."
        genhtml coverage/lcov.info -o coverage/html --quiet
        echo "HTML report: coverage/html/index.html"

        if [[ "$1" == "--open" ]]; then
            open coverage/html/index.html
        fi
    else
        echo ""
        echo "Warning: genhtml not found. Install lcov for HTML reports:"
        echo "  brew install lcov"
    fi
fi

echo ""
echo "Coverage data: coverage/lcov.info"
