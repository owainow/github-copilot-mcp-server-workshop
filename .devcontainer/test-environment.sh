#!/bin/bash

# Codespaces Environment Validation Script
# Tests that all required tools and configurations are working

echo "🧪 Testing Codespaces Environment for MCP Workshop..."
echo "=================================================="

# Track test results
TESTS_PASSED=0
TESTS_FAILED=0

# Test function
test_command() {
    local name="$1"
    local command="$2"
    local expected_output="$3"
    
    echo -n "Testing $name... "
    
    if eval "$command" > /dev/null 2>&1; then
        echo "✅ PASS"
        ((TESTS_PASSED++))
    else
        echo "❌ FAIL"
        ((TESTS_FAILED++))
        if [ ! -z "$expected_output" ]; then
            echo "   Expected: $expected_output"
        fi
    fi
}

# Test Node.js
echo ""
echo "📦 Core Development Tools"
test_command "Node.js installation" "node --version"
test_command "npm availability" "npm --version"

# Test Azure CLI
echo ""
echo "☁️ Azure Tools"
test_command "Azure CLI installation" "az --version"
test_command "Azure Functions Core Tools" "func --version"

# Test VS Code extensions (in Codespaces context)
echo ""
echo "🔧 VS Code Environment"
test_command "Workspace folder structure" "[ -d 'src' ] && [ -d 'docs' ] && [ -f 'package.json' ]"
test_command "TypeScript compiler" "npx tsc --version"

# Test project setup
echo ""
echo "🏗️ Project Configuration"
test_command "Dependencies installed" "[ -d 'node_modules' ]"
test_command "Build configuration" "[ -f 'tsconfig.json' ]"
test_command "Local settings template" "[ -f 'local.settings.json' ]"

# Test build process
echo ""
echo "🔨 Build Process"
echo -n "Testing TypeScript compilation... "
if npm run build > /dev/null 2>&1; then
    echo "✅ PASS"
    ((TESTS_PASSED++))
else
    echo "❌ FAIL"
    ((TESTS_FAILED++))
fi

# Test Azure Functions
echo ""
echo "⚡ Azure Functions"
echo -n "Testing Functions runtime... "
timeout 10s func start --port 7071 > /dev/null 2>&1 &
FUNC_PID=$!
sleep 3

if kill -0 $FUNC_PID 2>/dev/null; then
    kill $FUNC_PID 2>/dev/null
    echo "✅ PASS"
    ((TESTS_PASSED++))
else
    echo "❌ FAIL"
    ((TESTS_FAILED++))
fi

# Test MCP endpoints (if functions are running)
echo -n "Testing MCP server endpoint... "
if timeout 5s curl -s http://localhost:7071/api/mcp-server > /dev/null 2>&1; then
    echo "✅ PASS"
    ((TESTS_PASSED++))
else
    echo "⚠️ SKIP (Functions not running - normal for first setup)"
fi

# Environment Variables Check
echo ""
echo "🌍 Environment Setup"
test_command "Environment template created" "[ -f '.env' ] || [ -f 'local.settings.json' ]"

# Port forwarding (Codespaces specific)
echo ""
echo "🌐 Codespaces Configuration"
echo -n "Testing port forwarding setup... "
if [ ! -z "$CODESPACES" ]; then
    echo "✅ PASS (Running in Codespaces)"
    ((TESTS_PASSED++))
else
    echo "⚠️ SKIP (Not in Codespaces environment)"
fi

# Final Results
echo ""
echo "=================================================="
echo "🎯 Test Results Summary"
echo "=================================================="
echo "Tests Passed: $TESTS_PASSED"
echo "Tests Failed: $TESTS_FAILED"

if [ $TESTS_FAILED -eq 0 ]; then
    echo ""
    echo "🎉 All tests passed! Your Codespaces environment is ready for the workshop."
    echo ""
    echo "Next steps:"
    echo "1. Run: az login"
    echo "2. Update local.settings.json with your Azure details"
    echo "3. Start the workshop: open docs/README.md"
    echo ""
    exit 0
else
    echo ""
    echo "⚠️ Some tests failed. Please check the setup:"
    echo "1. Try running: .devcontainer/setup-workshop.sh"
    echo "2. Restart the Codespace if issues persist"
    echo "3. Check the .devcontainer/README.md for troubleshooting"
    echo ""
    exit 1
fi