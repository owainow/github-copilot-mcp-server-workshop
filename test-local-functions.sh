#!/bin/bash

# Test script for MCP server local development
# Part 2: Local Development Testing

set -e

echo "🧪 Testing MCP Server Local Development"
echo "======================================"

# Configuration
MCP_URL="http://localhost:7071/api/mcp-server"
TIMEOUT=10

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test function
test_endpoint() {
    local test_name="$1"
    local request_data="$2"
    local expected_check="$3"
    
    echo -e "\n${BLUE}Testing: $test_name${NC}"
    echo "Request URL: $MCP_URL"
    
    response=$(curl -s --max-time $TIMEOUT -X POST "$MCP_URL" \
        -H "Content-Type: application/json" \
        -d "$request_data" || echo "CURL_ERROR")
    
    if [[ "$response" == "CURL_ERROR" ]]; then
        echo -e "${RED}❌ FAILED: Could not connect to MCP server${NC}"
        echo -e "${YELLOW}💡 Make sure the function is running: func start --port 7071${NC}"
        return 1
    fi
    
    echo "Response: $response" | head -c 200
    echo "..."
    
    if echo "$response" | grep -q "$expected_check"; then
        echo -e "${GREEN}✅ PASSED: $test_name${NC}"
        return 0
    else
        echo -e "${RED}❌ FAILED: $test_name${NC}"
        echo -e "Expected to find: $expected_check"
        return 1
    fi
}

# Check if server is running
echo -e "\n${BLUE}Checking if MCP server is running...${NC}"
if ! curl -s --max-time 3 "$MCP_URL" > /dev/null 2>&1; then
    echo -e "${RED}❌ MCP server is not running at $MCP_URL${NC}"
    echo -e "${YELLOW}💡 Start the server with: func start --port 7071${NC}"
    exit 1
fi

echo -e "${GREEN}✅ MCP server is running${NC}"

# Test 1: Tool Discovery
test_endpoint "Tool Discovery" \
'{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "tools/list"
}' \
'"markdown_review"'

# Test 2: Markdown Review Tool
test_endpoint "Markdown Review Tool" \
'{
    "jsonrpc": "2.0",
    "id": 2,
    "method": "tools/call",
    "params": {
        "name": "markdown_review",
        "arguments": {
            "content": "# Test Document\n\nThis is a [broken link](nonexistent.md) and an image ![](test.jpg).",
            "analysis_type": "comprehensive"
        }
    }
}' \
'"quality_score"'

# Test 3: Dependency Check Tool
test_endpoint "Dependency Check Tool" \
'{
    "jsonrpc": "2.0",
    "id": 3,
    "method": "tools/call",
    "params": {
        "name": "dependency_check",
        "arguments": {
            "package_json": "{\"dependencies\":{\"lodash\":\"^3.10.1\",\"express\":\"^4.18.2\",\"moment\":\"^2.24.0\"}}"
        }
    }
}' \
'"total_dependencies"'

# Test 4: AI Code Review Tool (Mock Mode)
test_endpoint "AI Code Review Tool (Mock)" \
'{
    "jsonrpc": "2.0",
    "id": 4,
    "method": "tools/call",
    "params": {
        "name": "ai_code_review",
        "arguments": {
            "code": "function add(a, b) {\n  console.log(a + b);\n  return a + b;\n}",
            "language": "javascript",
            "review_type": "comprehensive"
        }
    }
}' \
'"mock_ai_analysis"'

# Test 5: Error Handling - Invalid Tool
test_endpoint "Error Handling - Invalid Tool" \
'{
    "jsonrpc": "2.0",
    "id": 5,
    "method": "tools/call",
    "params": {
        "name": "nonexistent_tool",
        "arguments": {}
    }
}' \
'"error"'

# Test 6: Error Handling - Invalid JSON-RPC Method
test_endpoint "Error Handling - Invalid Method" \
'{
    "jsonrpc": "2.0",
    "id": 6,
    "method": "invalid/method"
}' \
'"error"'

echo -e "\n${GREEN}🎉 All local development tests completed!${NC}"
echo -e "\n${BLUE}Summary:${NC}"
echo "- ✅ MCP server is running locally"
echo "- ✅ All three tools are operational"
echo "- ✅ Error handling works correctly"
echo "- ✅ JSON-RPC protocol is functioning"

echo -e "\n${YELLOW}Next Steps:${NC}"
echo "1. Continue to Part 3: Azure Deployment"
echo "2. Deploy to Azure Functions for global access"
echo "3. Test with GitHub Copilot integration"

echo -e "\n${BLUE}💡 Tips:${NC}"
echo "- Keep this terminal open while testing"
echo "- Use Ctrl+C to stop the function server when done"
echo "- Check the function logs for detailed debugging"