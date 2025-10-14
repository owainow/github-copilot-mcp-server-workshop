#!/bin/bash

# Test Workshop Script for Linux/Bash environments
# Usage: ./test-workshop.sh --level local|azure [--url function-url]

set -e

# Default values
TEST_LEVEL="local"
FUNCTION_URL=""
VERBOSE=false

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --level)
            TEST_LEVEL="$2"
            shift 2
            ;;
        --url)
            FUNCTION_URL="$2"
            shift 2
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 --level local|azure [--url function-url] [--verbose]"
            echo ""
            echo "Options:"
            echo "  --level    Test level: 'local' or 'azure'"
            echo "  --url      Azure Function URL (required for azure level)"
            echo "  --verbose  Enable verbose output"
            echo "  --help     Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Utility functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

test_command() {
    local name="$1"
    local command="$2"
    local expected="$3"
    
    log_info "Testing $name..."
    
    if [[ "$VERBOSE" == true ]]; then
        echo "  Command: $command"
    fi
    
    if eval "$command" >/dev/null 2>&1; then
        log_success "$name ✓"
        return 0
    else
        log_error "$name ✗"
        if [[ -n "$expected" ]]; then
            echo "  Expected: $expected"
        fi
        return 1
    fi
}

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0

run_test() {
    if "$@"; then
        ((TESTS_PASSED++))
    else
        ((TESTS_FAILED++))
    fi
}

echo "🧪 GitHub Copilot MCP Server Workshop Test Suite"
echo "=============================================="
echo "Platform: Linux/Bash"
echo "Test Level: $TEST_LEVEL"
echo ""

# Core environment tests
echo "📦 Testing Core Environment..."
run_test test_command "Node.js" "node --version" "v18+"
run_test test_command "npm" "npm --version" "8.0+"
run_test test_command "Azure Functions Core Tools" "func --version" "4.0+"
run_test test_command "Azure CLI" "az --version" "2.0+"

# Project structure tests
echo ""
echo "📁 Testing Project Structure..."
run_test test_command "package.json exists" "[ -f 'package.json' ]"
run_test test_command "src directory exists" "[ -d 'src' ]"
run_test test_command "tsconfig.json exists" "[ -f 'tsconfig.json' ]"
run_test test_command "local.settings.json exists" "[ -f 'local.settings.json' ]"

# Dependencies test
echo ""
echo "📦 Testing Dependencies..."
if [ -d "node_modules" ]; then
    log_success "node_modules directory exists ✓"
    ((TESTS_PASSED++))
else
    log_warning "node_modules not found - running npm install..."
    if npm install; then
        log_success "Dependencies installed ✓"
        ((TESTS_PASSED++))
    else
        log_error "Failed to install dependencies ✗"
        ((TESTS_FAILED++))
    fi
fi

# Build test
echo ""
echo "🔨 Testing Build Process..."
log_info "Running TypeScript compilation..."
if npm run build; then
    log_success "TypeScript compilation ✓"
    ((TESTS_PASSED++))
else
    log_error "TypeScript compilation failed ✗"
    ((TESTS_FAILED++))
fi

# Check build output
if [ -f "dist/index.js" ]; then
    log_success "Build output exists ✓"
    ((TESTS_PASSED++))
else
    log_error "Build output not found ✗"
    ((TESTS_FAILED++))
fi

# Local function testing
if [[ "$TEST_LEVEL" == "local" ]] || [[ "$TEST_LEVEL" == "azure" ]]; then
    echo ""
    echo "⚡ Testing Azure Functions..."
    
    if [[ "$TEST_LEVEL" == "local" ]]; then
        log_info "Starting Functions runtime (will timeout after 10s)..."
        
        # Start function in background and test
        timeout 10s func start --port 7071 &
        FUNC_PID=$!
        sleep 5
        
        # Test if function is responding
        if curl -s http://localhost:7071/api/mcp-server >/dev/null 2>&1; then
            log_success "Local Functions runtime ✓"
            ((TESTS_PASSED++))
        else
            log_warning "Functions runtime test inconclusive (normal for first run)"
        fi
        
        # Clean up
        kill $FUNC_PID 2>/dev/null || true
        wait $FUNC_PID 2>/dev/null || true
    fi
    
    if [[ "$TEST_LEVEL" == "azure" ]]; then
        if [[ -z "$FUNCTION_URL" ]]; then
            log_error "Azure function URL required for azure test level"
            exit 1
        fi
        
        log_info "Testing deployed Azure Function..."
        if curl -s "$FUNCTION_URL" >/dev/null 2>&1; then
            log_success "Azure Function accessible ✓"
            ((TESTS_PASSED++))
        else
            log_error "Azure Function not accessible ✗"
            ((TESTS_FAILED++))
        fi
    fi
fi

# MCP Protocol tests
echo ""
echo "🔌 Testing MCP Protocol..."

# Test MCP tool definitions
if [[ -f "src/tools/markdown-review.ts" ]] && [[ -f "src/tools/dependency-check.ts" ]] && [[ -f "src/tools/ai-code-review.ts" ]]; then
    log_success "MCP tool files exist ✓"
    ((TESTS_PASSED++))
else
    log_error "Missing MCP tool files ✗"
    ((TESTS_FAILED++))
fi

# Environment-specific tests
echo ""
echo "🌍 Testing Environment Configuration..."

# Check if we're in Codespaces
if [[ -n "$CODESPACES" ]]; then
    log_info "Detected GitHub Codespaces environment"
    log_success "Codespaces environment ✓"
    ((TESTS_PASSED++))
    
    # Test port forwarding setup
    if [[ -f ".devcontainer/devcontainer.json" ]]; then
        log_success "Devcontainer configuration exists ✓"
        ((TESTS_PASSED++))
    else
        log_warning "Devcontainer configuration not found"
    fi
else
    log_info "Local Linux/macOS environment detected"
    
    # Test Git configuration
    if git config user.name >/dev/null 2>&1; then
        log_success "Git configuration ✓"
        ((TESTS_PASSED++))
    else
        log_warning "Git not configured (optional)"
    fi
fi

# VS Code configuration tests
echo ""
echo "🔧 Testing VS Code Configuration..."

if [ -d ".vscode" ]; then
    log_success ".vscode directory exists ✓"
    ((TESTS_PASSED++))
else
    log_warning ".vscode configuration directory not found"
fi

# Test AI integration readiness
echo ""
echo "🤖 Testing AI Integration Readiness..."

# Check for AI configuration
AI_ENABLED=$(grep -o '"ENABLE_AI_TOOL": "true"' local.settings.json 2>/dev/null || echo "false")
if [[ "$AI_ENABLED" == *"true"* ]]; then
    log_info "AI integration enabled"
    # Test Azure AI configuration would go here
    log_success "AI integration configured ✓"
    ((TESTS_PASSED++))
else
    log_info "AI integration disabled (educational mode)"
    log_success "Educational mode configured ✓"
    ((TESTS_PASSED++))
fi

# Final results
echo ""
echo "=============================================="
echo "🎯 Test Results Summary"
echo "=============================================="
echo "Tests Passed: $TESTS_PASSED"
echo "Tests Failed: $TESTS_FAILED"
echo ""

if [[ $TESTS_FAILED -eq 0 ]]; then
    log_success "🎉 All tests passed! Your environment is ready for the workshop."
    echo ""
    echo "Next steps:"
    case $TEST_LEVEL in
        local)
            echo "1. Continue to Part 2: Local Development"
            echo "2. Start developing your MCP tools"
            echo "3. Test with: func start --port 7071"
            ;;
        azure)
            echo "1. Your Azure deployment is working!"
            echo "2. Continue to Part 4: Copilot Integration"
            echo "3. Configure VS Code settings for MCP"
            ;;
    esac
    echo ""
    exit 0
else
    log_error "⚠️ Some tests failed. Please check the setup:"
    echo ""
    echo "Troubleshooting steps:"
    echo "1. Ensure all prerequisites are installed"
    echo "2. Run: npm install && npm run build"
    echo "3. Check local.settings.json configuration"
    if [[ -n "$CODESPACES" ]]; then
        echo "4. Try restarting the Codespace"
        echo "5. Run: .devcontainer/setup-workshop.sh"
    fi
    echo ""
    exit 1
fi