#!/usr/bin/env node

/**
 * Quick Deployment Script for MCP Server
 * Deploys the MCP server to Azure Functions with minimal configuration
 */

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

class QuickDeploy {
    constructor() {
        this.functionAppName = process.env.AZURE_FUNCTION_APP_NAME || 'mcp-server-functions-' + Math.random().toString(36).substring(7);
        this.resourceGroup = process.env.AZURE_RESOURCE_GROUP || 'mcp-workshop-rg';
        this.region = process.env.AZURE_REGION || 'eastus';
    }

    log(message, type = 'info') {
        const timestamp = new Date().toISOString();
        const symbols = {
            info: 'ℹ️',
            success: '✅',
            error: '❌',
            warn: '⚠️',
            deploy: '🚀'
        };
        
        console.log(`${symbols[type]} [${timestamp}] ${message}`);
    }

    checkPrerequisites() {
        this.log('Checking deployment prerequisites...', 'info');

        // Check if Azure CLI is authenticated
        try {
            const account = execSync('az account show', { encoding: 'utf8' });
            const accountInfo = JSON.parse(account);
            this.log(`Authenticated as: ${accountInfo.user.name}`, 'success');
            this.log(`Subscription: ${accountInfo.name} (${accountInfo.id})`, 'success');
        } catch (error) {
            throw new Error('Azure CLI not authenticated. Please run: az login');
        }

        // Check if project is built
        const distPath = path.join(process.cwd(), 'dist');
        if (!fs.existsSync(distPath)) {
            this.log('Building project...', 'info');
            execSync('npm run build', { stdio: 'inherit' });
        }

        this.log('Prerequisites check completed ✅', 'success');
    }

    createResourceGroup() {
        this.log(`Creating resource group: ${this.resourceGroup}`, 'deploy');

        try {
            // Check if exists first
            execSync(`az group show --name ${this.resourceGroup}`, { stdio: 'pipe' });
            this.log('Resource group already exists', 'info');
        } catch (error) {
            // Create resource group
            execSync(`az group create --name ${this.resourceGroup} --location ${this.region}`, { stdio: 'inherit' });
            this.log('Resource group created successfully', 'success');
        }
    }

    deployInfrastructure() {
        this.log('Deploying Azure infrastructure...', 'deploy');

        const deployCommand = `az deployment group create \
            --resource-group ${this.resourceGroup} \
            --template-file infra/main.bicep \
            --parameters functionAppName=${this.functionAppName} location=${this.region}`;

        try {
            const result = execSync(deployCommand, { encoding: 'utf8', stdio: 'pipe' });
            const deployment = JSON.parse(result);
            
            this.log('Infrastructure deployment completed', 'success');
            
            // Extract outputs
            if (deployment.properties && deployment.properties.outputs) {
                const outputs = deployment.properties.outputs;
                this.functionAppUrl = outputs.functionAppUrl?.value;
                this.log(`Function App URL: ${this.functionAppUrl}`, 'success');
            }
        } catch (error) {
            this.log('Infrastructure deployment output:', 'info');
            console.log(error.stdout);
            throw new Error('Infrastructure deployment failed');
        }
    }

    deployFunctionCode() {
        this.log('Deploying function code...', 'deploy');

        try {
            execSync(`func azure functionapp publish ${this.functionAppName}`, { stdio: 'inherit' });
            this.log('Function code deployed successfully', 'success');
        } catch (error) {
            throw new Error('Function code deployment failed');
        }
    }

    testDeployment() {
        this.log('Testing deployed function...', 'info');

        if (!this.functionAppUrl) {
            // Try to get the URL
            try {
                const result = execSync(`az functionapp show --name ${this.functionAppName} --resource-group ${this.resourceGroup} --query "defaultHostName" -o tsv`, { encoding: 'utf8' });
                this.functionAppUrl = `https://${result.trim()}`;
            } catch (error) {
                this.log('Could not retrieve function app URL', 'warn');
                return;
            }
        }

        const testUrl = `${this.functionAppUrl}/api/mcp-server`;
        const testPayload = JSON.stringify({
            jsonrpc: '2.0',
            id: 1,
            method: 'ping'
        });

        try {
            // Use curl to test the endpoint
            const curlCommand = `curl -X POST "${testUrl}" \
                -H "Content-Type: application/json" \
                -d '${testPayload}' \
                --max-time 30`;

            const response = execSync(curlCommand, { encoding: 'utf8' });
            const result = JSON.parse(response);

            if (result.result && result.result.status === 'ok') {
                this.log('Deployment test successful! 🎉', 'success');
                this.log(`Server: ${result.result.server}`, 'info');
                this.log(`Version: ${result.result.version}`, 'info');
            } else {
                this.log('Test response received but unexpected format', 'warn');
                console.log('Response:', response);
            }
        } catch (error) {
            this.log('Deployment test failed, but this may be normal for new deployments', 'warn');
            this.log('Function may need a few minutes to fully start up', 'info');
        }
    }

    generateMCPConfig() {
        const mcpConfig = {
            mcpServers: {
                "azure-functions-mcp": {
                    command: "npx",
                    args: ["@modelcontextprotocol/server-fetch"],
                    env: {
                        FETCH_BASE_URL: `${this.functionAppUrl}/api`
                    }
                }
            }
        };

        const configPath = path.join(process.cwd(), 'mcp-config.json');
        fs.writeFileSync(configPath, JSON.stringify(mcpConfig, null, 2));
        
        this.log(`MCP configuration written to: ${configPath}`, 'success');
    }

    generateSummary() {
        this.log('\n' + '='.repeat(70), 'info');
        this.log('🎉 DEPLOYMENT COMPLETED SUCCESSFULLY!', 'success');
        this.log('='.repeat(70), 'info');

        this.log('\n📋 DEPLOYMENT SUMMARY:', 'info');
        this.log(`• Function App: ${this.functionAppName}`, 'info');
        this.log(`• Resource Group: ${this.resourceGroup}`, 'info');
        this.log(`• Region: ${this.region}`, 'info');
        if (this.functionAppUrl) {
            this.log(`• URL: ${this.functionAppUrl}`, 'info');
        }

        this.log('\n🔧 NEXT STEPS:', 'info');
        this.log('1. Configure GitHub Copilot to use your MCP server:', 'info');
        this.log('   - Add the generated mcp-config.json to your Copilot settings', 'info');
        this.log('2. Test the integration:', 'info');
        this.log('   - Ask Copilot: "Can you review my markdown files?"', 'info');
        this.log('   - Ask Copilot: "Please check my dependencies for security issues"', 'info');

        this.log('\n🔗 USEFUL LINKS:', 'info');
        if (this.functionAppUrl) {
            this.log(`• Function App: ${this.functionAppUrl}`, 'info');
        }
        this.log(`• Azure Portal: https://portal.azure.com/#@/resource/subscriptions/$(az account show --query id -o tsv)/resourceGroups/${this.resourceGroup}/providers/Microsoft.Web/sites/${this.functionAppName}`, 'info');
        this.log('• Workshop Documentation: ./docs/', 'info');

        this.log('\n🆘 TROUBLESHOOTING:', 'info');
        this.log('• Check function logs in Azure Portal if issues occur', 'info');
        this.log('• Verify CORS settings if getting connection errors', 'info');
        this.log('• Test endpoints manually with the examples/ directory', 'info');

        this.log('\n💡 TIP:', 'info');
        this.log('Your MCP server is now ready to extend GitHub Copilot\'s capabilities!', 'info');
    }

    async run() {
        try {
            this.log('🚀 Starting Quick Deployment of MCP Server', 'deploy');
            this.log(`Target Function App: ${this.functionAppName}`, 'info');

            this.checkPrerequisites();
            this.createResourceGroup();
            this.deployInfrastructure();
            this.deployFunctionCode();
            this.testDeployment();
            this.generateMCPConfig();
            this.generateSummary();

        } catch (error) {
            this.log(`❌ Deployment failed: ${error.message}`, 'error');
            this.log('\n🔍 TROUBLESHOOTING STEPS:', 'info');
            this.log('1. Check Azure CLI authentication: az account show', 'info');
            this.log('2. Verify subscription permissions', 'info');
            this.log('3. Check resource group and function app name availability', 'info');
            this.log('4. Review error logs above for specific issues', 'info');
            process.exit(1);
        }
    }
}

// Run deployment if this script is executed directly
if (require.main === module) {
    const deploy = new QuickDeploy();
    deploy.run();
}

module.exports = QuickDeploy;
