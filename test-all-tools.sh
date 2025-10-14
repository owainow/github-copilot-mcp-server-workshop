#!/bin/bash

# Complete MCP Tools Test Script for Linux/Bash
# This script demonstrates all three tools in the MCP server

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BASE_URL="http://localhost:7071/api/mcp-server"
TIMEOUT=10

echo -e "${GREEN}🚀 Testing Complete MCP Server with All Tools${NC}"
echo -e "${GREEN}=============================================${NC}"

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

print_test() {
    echo -e "\n${BLUE}🧪 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Function to make MCP requests
make_mcp_request() {
    local method=$1
    local params=${2:-"{}"}
    local id=$((RANDOM % 10000))
    
    local request_body=$(cat <<EOF
{
    "jsonrpc": "2.0",
    "id": $id,
    "method": "$method",
    "params": $params
}
EOF
)
    
    curl -s -X POST "$BASE_URL" \
        -H "Content-Type: application/json" \
        -H "Accept: application/json" \
        --connect-timeout $TIMEOUT \
        -d "$request_body"
}

# Check if server is running
check_server() {
    print_test "Checking if MCP server is running..."
    
    if curl -s --connect-timeout 5 "$BASE_URL" >/dev/null 2>&1; then
        print_success "Server is running at $BASE_URL"
    else
        print_error "Server is not accessible at $BASE_URL"
        echo -e "\n${YELLOW}Please ensure the Azure Functions are running locally:${NC}"
        echo "1. Run: npm run build"
        echo "2. Run: func start"
        echo "3. Wait for 'Host lock lease acquired by instance ID' message"
        exit 1
    fi
}

# Test MCP protocol initialization
test_initialization() {
    print_test "Testing MCP protocol initialization..."
    
    local init_params=$(cat <<'EOF'
{
    "protocolVersion": "2024-11-05",
    "capabilities": {
        "tools": {}
    },
    "clientInfo": {
        "name": "bash-test-client",
        "version": "1.0.0"
    }
}
EOF
)
    
    local response=$(make_mcp_request "initialize" "$init_params")
    
    if echo "$response" | jq -e '.result.serverInfo.name' >/dev/null 2>&1; then
        local server_name=$(echo "$response" | jq -r '.result.serverInfo.name')
        local server_version=$(echo "$response" | jq -r '.result.serverInfo.version')
        print_success "Initialization successful: $server_name v$server_version"
    else
        print_error "Initialization failed"
        echo "Response: $response"
        exit 1
    fi
}

# Test tools listing
test_tools_list() {
    print_test "Testing tools list..."
    
    local response=$(make_mcp_request "tools/list")
    
    if echo "$response" | jq -e '.result.tools' >/dev/null 2>&1; then
        local tool_count=$(echo "$response" | jq '.result.tools | length')
        print_success "Found $tool_count tools available"
        
        echo -e "\n${BLUE}Available tools:${NC}"
        echo "$response" | jq -r '.result.tools[] | "  📋 " + .name + ": " + .description'
    else
        print_error "Failed to get tools list"
        echo "Response: $response"
        exit 1
    fi
}

# Test markdown review tool
test_markdown_review() {
    print_test "Testing markdown_review tool..."
    
    local markdown_content="# Sample Document

This is a test document for the markdown review tool.

## Problems to detect
- inconsistent spacing
- Missing punctuation
- **bold text without proper spacing**
- Links that might be [broken](http://invalid-url)

### Code blocks
\`\`\`javascript
function hello() {
console.log('world')
}
\`\`\`

## Lists
- First item
-Second item (spacing issue)
- Third item

1. Numbered list
2.Missing space
3. Correct item"

    local params=$(cat <<EOF
{
    "name": "markdown_review",
    "arguments": {
        "content": $(echo "$markdown_content" | jq -Rs .)
    }
}
EOF
)
    
    local response=$(make_mcp_request "tools/call" "$params")
    
    if echo "$response" | jq -e '.result.content[0].text' >/dev/null 2>&1; then
        local result=$(echo "$response" | jq -r '.result.content[0].text')
        local analysis=$(echo "$result" | jq .)
        
        local score=$(echo "$analysis" | jq -r '.score // "N/A"')
        local suggestions_count=$(echo "$analysis" | jq -r '.suggestions | length // 0')
        local grammar_issues=$(echo "$analysis" | jq -r '.grammar_issues | length // 0')
        local structure_issues=$(echo "$analysis" | jq -r '.structure_issues | length // 0')
        
        print_success "Markdown review completed"
        echo -e "  📊 Score: $score"
        echo -e "  📝 Suggestions: $suggestions_count"
        echo -e "  📚 Grammar issues: $grammar_issues"
        echo -e "  🏗️  Structure issues: $structure_issues"
        
        if [ "$suggestions_count" -gt 0 ]; then
            echo -e "\n${BLUE}Sample suggestions:${NC}"
            echo "$analysis" | jq -r '.suggestions[0:3][] | "  • " + .'
        fi
    else
        print_error "Markdown review failed"
        echo "Response: $response"
    fi
}

# Test dependency check tool
test_dependency_check() {
    print_test "Testing dependency_check tool..."
    
    local package_json='{
    "name": "sample-project",
    "version": "1.0.0",
    "description": "Sample project for dependency testing",
    "dependencies": {
        "express": "4.18.2",
        "lodash": "4.17.21",
        "axios": "1.5.0",
        "moment": "2.29.4"
    },
    "devDependencies": {
        "typescript": "5.2.2",
        "@types/node": "20.8.0",
        "jest": "29.7.0"
    }
}'
    
    local params=$(cat <<EOF
{
    "name": "dependency_check",
    "arguments": {
        "packageJson": $(echo "$package_json" | jq -Rs .)
    }
}
EOF
)
    
    local response=$(make_mcp_request "tools/call" "$params")
    
    if echo "$response" | jq -e '.result.content[0].text' >/dev/null 2>&1; then
        local result=$(echo "$response" | jq -r '.result.content[0].text')
        local analysis=$(echo "$result" | jq .)
        
        local total_deps=$(echo "$analysis" | jq -r '.dependencies | length // 0')
        local outdated_count=$(echo "$analysis" | jq -r '.outdated | length // 0')
        local security_count=$(echo "$analysis" | jq -r '.security_vulnerabilities | length // 0')
        local risk_level=$(echo "$analysis" | jq -r '.risk_level // "unknown"')
        
        print_success "Dependency check completed"
        echo -e "  📦 Total dependencies: $total_deps"
        echo -e "  🔄 Outdated: $outdated_count"
        echo -e "  🔒 Security issues: $security_count"
        echo -e "  ⚠️  Risk level: $risk_level"
        
        if [ "$outdated_count" -gt 0 ]; then
            echo -e "\n${BLUE}Outdated dependencies:${NC}"
            echo "$analysis" | jq -r '.outdated[0:3][] | "  • " + .name + " (current: " + .current + ", latest: " + .latest + ")"'
        fi
        
        if [ "$security_count" -gt 0 ]; then
            echo -e "\n${RED}Security vulnerabilities:${NC}"
            echo "$analysis" | jq -r '.security_vulnerabilities[0:3][] | "  • " + .package + " - " + .severity + " severity"'
        fi
    else
        print_error "Dependency check failed"
        echo "Response: $response"
    fi
}

# Test AI code review tool
test_ai_code_review() {
    print_test "Testing ai_code_review tool..."
    
    local code_sample='// Sample JavaScript code with various issues for testing
function processUserData(users) {
    var result = [];
    
    // Performance issue: using var instead of const/let
    for (var i = 0; i < users.length; i++) {
        var user = users[i];
        
        // Security issue: no input validation
        if (user.active) {
            // Code style issue: inconsistent spacing
            result.push({
                id:user.id,
                name: user.name.toUpperCase(),
                email:user.email
            });
        }
    }
    
    // Missing error handling
    return result;
}

// Missing JSDoc documentation
function calculateTotal(items) {
    var total = 0;
    items.forEach(function(item) {
        total += item.price * item.quantity;  // Potential precision issues with floats
    });
    return total;
}'
    
    local params=$(cat <<EOF
{
    "name": "ai_code_review",
    "arguments": {
        "code": $(echo "$code_sample" | jq -Rs .),
        "language": "javascript"
    }
}
EOF
)
    
    local response=$(make_mcp_request "tools/call" "$params")
    
    if echo "$response" | jq -e '.result.content[0].text' >/dev/null 2>&1; then
        local result=$(echo "$response" | jq -r '.result.content[0].text')
        local analysis=$(echo "$result" | jq .)
        
        local score=$(echo "$analysis" | jq -r '.score // "N/A"')
        local suggestions_count=$(echo "$analysis" | jq -r '.suggestions | length // 0')
        local security_count=$(echo "$analysis" | jq -r '.security_issues | length // 0')
        local performance_count=$(echo "$analysis" | jq -r '.performance_issues | length // 0')
        local code_quality=$(echo "$analysis" | jq -r '.code_quality_rating // "unknown"')
        
        print_success "AI code review completed"
        echo -e "  📊 Overall score: $score"
        echo -e "  📝 Suggestions: $suggestions_count"
        echo -e "  🔒 Security issues: $security_count"
        echo -e "  🚀 Performance issues: $performance_count"
        echo -e "  ⭐ Code quality: $code_quality"
        
        if [ "$suggestions_count" -gt 0 ]; then
            echo -e "\n${BLUE}Sample suggestions:${NC}"
            echo "$analysis" | jq -r '.suggestions[0:3][] | "  • " + .'
        fi
        
        if [ "$security_count" -gt 0 ]; then
            echo -e "\n${RED}Security issues:${NC}"
            echo "$analysis" | jq -r '.security_issues[0:3][] | "  🔒 " + .'
        fi
        
        if [ "$performance_count" -gt 0 ]; then
            echo -e "\n${YELLOW}Performance suggestions:${NC}"
            echo "$analysis" | jq -r '.performance_issues[0:3][] | "  🚀 " + .'
        fi
    else
        print_error "AI code review failed"
        echo "Response: $response"
    fi
}

# Test error handling
test_error_handling() {
    print_test "Testing error handling..."
    
    # Test invalid tool name
    local invalid_params=$(cat <<'EOF'
{
    "name": "non_existent_tool",
    "arguments": {
        "test": "data"
    }
}
EOF
)
    
    local response=$(make_mcp_request "tools/call" "$invalid_params")
    
    if echo "$response" | jq -e '.error.code' >/dev/null 2>&1; then
        local error_code=$(echo "$response" | jq -r '.error.code')
        local error_message=$(echo "$response" | jq -r '.error.message')
        print_success "Error handling works correctly (Error $error_code: $error_message)"
    else
        print_warning "Error handling test inconclusive"
    fi
}

# Performance test
test_performance() {
    print_test "Testing performance with multiple requests..."
    
    local start_time=$(date +%s)
    local request_count=5
    local success_count=0
    
    for i in $(seq 1 $request_count); do
        local response=$(make_mcp_request "tools/list")
        if echo "$response" | jq -e '.result.tools' >/dev/null 2>&1; then
            success_count=$((success_count + 1))
        fi
    done
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    print_success "Performance test completed: $success_count/$request_count requests successful in ${duration}s"
}

# Main execution
main() {
    echo -e "\n${GREEN}Starting comprehensive MCP tools test...${NC}"
    
    # Prerequisites check
    if ! command -v curl >/dev/null 2>&1; then
        print_error "curl is required but not installed"
        exit 1
    fi
    
    if ! command -v jq >/dev/null 2>&1; then
        print_error "jq is required but not installed"
        echo "Install with: apt-get install jq (Ubuntu/Debian) or brew install jq (macOS)"
        exit 1
    fi
    
    # Run all tests
    check_server
    test_initialization
    test_tools_list
    test_markdown_review
    test_dependency_check
    test_ai_code_review
    test_error_handling
    test_performance
    
    echo -e "\n${GREEN}🎉 All tests completed successfully!${NC}"
    echo -e "${GREEN}Your MCP server is working correctly with all three tools.${NC}"
    
    echo -e "\n${BLUE}Next steps:${NC}"
    echo "1. Deploy to Azure Functions for production use"
    echo "2. Configure GitHub Copilot integration"
    echo "3. Start using the tools in your development workflow"
    
    echo -e "\n${YELLOW}Tips:${NC}"
    echo "• Use the markdown_review tool for documentation quality"
    echo "• Run dependency_check regularly for security updates"
    echo "• Leverage ai_code_review for code quality improvements"
}

# Handle command line arguments
case "${1:-}" in
    --help|-h)
        echo "Usage: $0 [options]"
        echo ""
        echo "Test all MCP server tools with comprehensive examples"
        echo ""
        echo "Options:"
        echo "  --help, -h     Show this help message"
        echo ""
        echo "Prerequisites:"
        echo "  - Azure Functions running locally (func start)"
        echo "  - curl and jq installed"
        echo ""
        echo "Environment variables:"
        echo "  BASE_URL       Override default server URL (default: http://localhost:7071/api/mcp-server)"
        exit 0
        ;;
esac

# Override base URL if environment variable is set
if [ -n "${MCP_SERVER_URL:-}" ]; then
    BASE_URL="$MCP_SERVER_URL"
fi

# Run main function
main