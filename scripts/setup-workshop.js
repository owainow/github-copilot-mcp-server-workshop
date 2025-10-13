#!/usr/bin/env node

/**
 * Workshop Setup Script
 * Automates the initial setup process for the MCP server workshop
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

class WorkshopSetup {
    constructor() {
        this.projectRoot = process.cwd();
        this.errors = [];
        this.warnings = [];
    }

    log(message, type = 'info') {
        const timestamp = new Date().toISOString();
        const prefix = {
            info: '✅',
            warn: '⚠️',
            error: '❌',
            success: '🎉'
        }[type] || 'ℹ️';
        
        console.log(`${prefix} [${timestamp}] ${message}`);
    }

    checkPrerequisites() {
        this.log('Checking prerequisites...', 'info');

        // Check Node.js version
        try {
            const nodeVersion = execSync('node --version', { encoding: 'utf8' }).trim();
            const majorVersion = parseInt(nodeVersion.substring(1).split('.')[0]);
            
            if (majorVersion >= 18) {
                this.log(`Node.js version: ${nodeVersion} ✓`, 'success');
            } else {
                this.errors.push(`Node.js version ${nodeVersion} is too old. Please install v18 or later.`);
            }
        } catch (error) {
            this.errors.push('Node.js is not installed or not in PATH.');
        }

        // Check Azure CLI
        try {
            const azVersion = execSync('az --version', { encoding: 'utf8' });
            this.log('Azure CLI is installed ✓', 'success');
        } catch (error) {
            this.errors.push('Azure CLI is not installed. Please install from https://docs.microsoft.com/cli/azure/install-azure-cli');
        }

        // Check Azure Functions Core Tools
        try {
            const funcVersion = execSync('func --version', { encoding: 'utf8' }).trim();
            this.log(`Azure Functions Core Tools: ${funcVersion} ✓`, 'success');
        } catch (error) {
            this.errors.push('Azure Functions Core Tools not installed. Run: npm install -g azure-functions-core-tools@4');
        }

        // Check if logged into Azure
        try {
            execSync('az account show', { encoding: 'utf8' });
            this.log('Azure CLI authenticated ✓', 'success');
        } catch (error) {
            this.warnings.push('Azure CLI not authenticated. Run: az login');
        }
    }

    setupEnvironment() {
        this.log('Setting up environment configuration...', 'info');

        const envPath = path.join(this.projectRoot, '.env');
        const exampleEnvPath = path.join(this.projectRoot, '.env.example');

        if (!fs.existsSync(envPath)) {
            if (fs.existsSync(exampleEnvPath)) {
                fs.copyFileSync(exampleEnvPath, envPath);
                this.log('Created .env file from .env.example ✓', 'success');
                this.warnings.push('Please update .env file with your Azure subscription ID and other settings.');
            } else {
                this.errors.push('.env.example file not found. Please check project structure.');
            }
        } else {
            this.log('.env file already exists ✓', 'success');
        }
    }

    installDependencies() {
        this.log('Installing Node.js dependencies...', 'info');

        try {
            execSync('npm install', { stdio: 'inherit' });
            this.log('Dependencies installed successfully ✓', 'success');
        } catch (error) {
            this.errors.push('Failed to install dependencies. Please run: npm install');
        }
    }

    buildProject() {
        this.log('Building TypeScript project...', 'info');

        try {
            execSync('npm run build', { stdio: 'inherit' });
            this.log('Project built successfully ✓', 'success');
        } catch (error) {
            this.errors.push('Build failed. Please check TypeScript errors and run: npm run build');
        }
    }

    createResourceGroup() {
        this.log('Creating Azure resource group...', 'info');

        try {
            // Check if resource group already exists
            try {
                execSync('az group show --name mcp-workshop-rg', { stdio: 'pipe' });
                this.log('Resource group mcp-workshop-rg already exists ✓', 'success');
                return;
            } catch (error) {
                // Resource group doesn't exist, create it
            }

            execSync('az group create --name mcp-workshop-rg --location eastus', { stdio: 'inherit' });
            this.log('Resource group created successfully ✓', 'success');
        } catch (error) {
            this.warnings.push('Failed to create resource group. You may need to create it manually or check Azure CLI authentication.');
        }
    }

    testLocalServer() {
        this.log('Testing local server startup...', 'info');

        try {
            // Start the function app in the background
            const funcProcess = execSync('timeout 30 func start', { 
                stdio: 'pipe',
                timeout: 30000 
            });

            this.log('Local server test passed ✓', 'success');
        } catch (error) {
            this.warnings.push('Local server test failed. You may need to run "func start" manually to test.');
        }
    }

    generateSummary() {
        this.log('\n' + '='.repeat(60), 'info');
        this.log('WORKSHOP SETUP SUMMARY', 'info');
        this.log('='.repeat(60), 'info');

        if (this.errors.length === 0) {
            this.log('🎉 Setup completed successfully!', 'success');
        } else {
            this.log('⚠️ Setup completed with issues that need attention.', 'warn');
        }

        if (this.errors.length > 0) {
            this.log('\n❌ ERRORS TO FIX:', 'error');
            this.errors.forEach((error, index) => {
                this.log(`${index + 1}. ${error}`, 'error');
            });
        }

        if (this.warnings.length > 0) {
            this.log('\n⚠️ WARNINGS:', 'warn');
            this.warnings.forEach((warning, index) => {
                this.log(`${index + 1}. ${warning}`, 'warn');
            });
        }

        this.log('\n📖 NEXT STEPS:', 'info');
        if (this.errors.length > 0) {
            this.log('1. Fix the errors listed above', 'info');
            this.log('2. Re-run this script: npm run workshop:setup', 'info');
        } else {
            this.log('1. Update your .env file with your Azure subscription ID', 'info');
            this.log('2. Start the local server: npm start', 'info');
            this.log('3. Continue with the workshop documentation', 'info');
        }

        this.log('\n📚 DOCUMENTATION:', 'info');
        this.log('- Main README: ./README.md', 'info');
        this.log('- Workshop docs: ./docs/', 'info');
        this.log('- Examples: ./examples/', 'info');

        this.log('\n🆘 HELP:', 'info');
        this.log('If you encounter issues, check the troubleshooting section in the documentation.', 'info');
    }

    async run() {
        this.log('🚀 Starting MCP Server Workshop Setup', 'success');
        this.log('This script will prepare your development environment.\n', 'info');

        this.checkPrerequisites();
        
        if (this.errors.length === 0) {
            this.setupEnvironment();
            this.installDependencies();
            this.buildProject();
            this.createResourceGroup();
        }

        this.generateSummary();

        // Exit with error code if there were critical errors
        if (this.errors.length > 0) {
            process.exit(1);
        }
    }
}

// Run the setup if this script is executed directly
if (require.main === module) {
    const setup = new WorkshopSetup();
    setup.run().catch(error => {
        console.error('❌ Setup script failed:', error);
        process.exit(1);
    });
}

module.exports = WorkshopSetup;
