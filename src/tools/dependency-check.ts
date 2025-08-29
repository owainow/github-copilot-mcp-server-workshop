import { MCPTool } from '../mcp/server';
import { Logger } from '../shared/logger';
import * as semver from 'semver';

/**
 * Dependency Check Tool for GitHub Copilot
 * Analyzes project dependencies for security, updates, and compatibility
 */
export class DependencyCheckTool implements MCPTool {
    name = 'dependency_check';
    description = 'Analyze project dependencies for security vulnerabilities, outdated packages, and compatibility issues';
    
    parameters = {
        package_json: {
            type: 'string',
            description: 'Content of package.json file to analyze'
        },
        check_type: {
            type: 'string',
            description: 'Type of dependency check: security, updates, or comprehensive',
            enum: ['security', 'updates', 'comprehensive'],
            default: 'comprehensive'
        },
        include_dev_dependencies: {
            type: 'boolean',
            description: 'Whether to include devDependencies in the analysis',
            default: true
        }
    };

    private logger: Logger;

    constructor(logger: Logger) {
        this.logger = logger;
    }

    async execute(args: Record<string, any>): Promise<any> {
        const startTime = Date.now();
        
        try {
            const { package_json, check_type = 'comprehensive', include_dev_dependencies = true } = args;

            if (!package_json || typeof package_json !== 'string') {
                throw new Error('package_json parameter is required and must be a string');
            }

            this.logger.info('Starting dependency check', {
                checkType: check_type,
                includeDevDeps: include_dev_dependencies
            });

            const packageData = JSON.parse(package_json);
            const analysis = await this.analyzeDependencies(packageData, check_type, include_dev_dependencies);
            
            this.logger.logPerformance('dependency_check', startTime, true, {
                totalDependencies: analysis.summary.totalDependencies,
                vulnerabilities: analysis.security.vulnerabilities.length,
                outdated: analysis.updates.outdated.length
            });

            return analysis;

        } catch (error) {
            this.logger.error('Dependency check failed', { error, args });
            this.logger.logPerformance('dependency_check', startTime, false);
            throw error;
        }
    }

    private async analyzeDependencies(packageData: any, checkType: string, includeDevDeps: boolean): Promise<any> {
        const dependencies = packageData.dependencies || {};
        const devDependencies = includeDevDeps ? (packageData.devDependencies || {}) : {};
        const allDependencies = { ...dependencies, ...devDependencies };

        const analysis = {
            summary: {
                projectName: packageData.name,
                projectVersion: packageData.version,
                totalDependencies: Object.keys(allDependencies).length,
                productionDependencies: Object.keys(dependencies).length,
                devDependencies: Object.keys(devDependencies).length,
                checkType,
                timestamp: new Date().toISOString()
            },
            security: {
                vulnerabilities: [] as any[],
                riskScore: 0,
                recommendations: [] as any[]
            },
            updates: {
                outdated: [] as any[],
                recommendations: [] as any[]
            },
            compatibility: {
                issues: [] as any[],
                nodeVersionCheck: this.checkNodeVersion(packageData),
                recommendations: [] as any[]
            },
            insights: [] as any[]
        };

        // Security analysis
        if (checkType === 'security' || checkType === 'comprehensive') {
            analysis.security = await this.performSecurityAnalysis(allDependencies);
        }

        // Update analysis
        if (checkType === 'updates' || checkType === 'comprehensive') {
            analysis.updates = await this.performUpdateAnalysis(allDependencies);
        }

        // Compatibility analysis
        if (checkType === 'comprehensive') {
            analysis.compatibility = await this.performCompatibilityAnalysis(allDependencies, packageData);
        }

        // Generate insights
        analysis.insights = this.generateInsights(analysis);

        return analysis;
    }

    private async performSecurityAnalysis(dependencies: Record<string, string>): Promise<any> {
        const vulnerabilities = [];
        const recommendations = [];
        let riskScore = 0;

        // Known vulnerable packages (this would normally come from a security database)
        const knownVulnerabilities = this.getKnownVulnerabilities();

        for (const [packageName, version] of Object.entries(dependencies)) {
            const cleanVersion = this.cleanVersion(version);
            
            // Check against known vulnerabilities
            const vulns = knownVulnerabilities.filter(v => 
                v.package === packageName && 
                this.isVersionAffected(cleanVersion, v.affectedVersions)
            );

            vulnerabilities.push(...vulns.map(v => ({
                ...v,
                currentVersion: cleanVersion,
                severity: v.severity
            })));

            // Calculate risk score
            vulns.forEach(v => {
                switch (v.severity) {
                    case 'critical': riskScore += 10; break;
                    case 'high': riskScore += 7; break;
                    case 'medium': riskScore += 4; break;
                    case 'low': riskScore += 1; break;
                }
            });
        }

        // Generate security recommendations
        if (vulnerabilities.length > 0) {
            recommendations.push({
                type: 'immediate_action',
                priority: 'high',
                message: `Found ${vulnerabilities.length} security vulnerabilities`,
                action: 'Update affected packages immediately'
            });
        }

        if (riskScore > 20) {
            recommendations.push({
                type: 'security_audit',
                priority: 'high',
                message: 'High security risk detected',
                action: 'Perform comprehensive security audit'
            });
        }

        return { vulnerabilities, riskScore, recommendations };
    }

    private async performUpdateAnalysis(dependencies: Record<string, string>): Promise<any> {
        const outdated = [];
        const recommendations = [];

        // Mock version data (in real implementation, this would query npm registry)
        const mockLatestVersions = this.getMockLatestVersions();

        for (const [packageName, version] of Object.entries(dependencies)) {
            const cleanVersion = this.cleanVersion(version);
            const latestVersion = mockLatestVersions[packageName];

            if (latestVersion && semver.lt(cleanVersion, latestVersion)) {
                const updateType = this.getUpdateType(cleanVersion, latestVersion);
                outdated.push({
                    package: packageName,
                    currentVersion: cleanVersion,
                    latestVersion,
                    updateType,
                    versionsBehind: this.countVersionsBehind(cleanVersion, latestVersion)
                });
            }
        }

        // Generate update recommendations
        const majorUpdates = outdated.filter(p => p.updateType === 'major');
        const minorUpdates = outdated.filter(p => p.updateType === 'minor');
        const patchUpdates = outdated.filter(p => p.updateType === 'patch');

        if (majorUpdates.length > 0) {
            recommendations.push({
                type: 'major_updates',
                priority: 'medium',
                message: `${majorUpdates.length} package(s) have major updates available`,
                action: 'Review breaking changes before updating',
                packages: majorUpdates.map(p => p.package)
            });
        }

        if (minorUpdates.length > 0) {
            recommendations.push({
                type: 'minor_updates',
                priority: 'low',
                message: `${minorUpdates.length} package(s) have minor updates available`,
                action: 'Safe to update, new features available'
            });
        }

        if (patchUpdates.length > 0) {
            recommendations.push({
                type: 'patch_updates',
                priority: 'low',
                message: `${patchUpdates.length} package(s) have patch updates available`,
                action: 'Recommended to update for bug fixes'
            });
        }

        return { outdated, recommendations };
    }

    private async performCompatibilityAnalysis(dependencies: Record<string, string>, packageData: any): Promise<any> {
        const issues = [];
        const recommendations: any[] = [];

        // Check for peer dependency conflicts
        const peerDeps = packageData.peerDependencies || {};
        for (const [peerDep, requiredVersion] of Object.entries(peerDeps)) {
            const installedVersion = dependencies[peerDep];
            if (installedVersion && !semver.satisfies(this.cleanVersion(installedVersion), requiredVersion as string)) {
                issues.push({
                    type: 'peer_dependency_conflict',
                    package: peerDep,
                    required: requiredVersion,
                    installed: installedVersion,
                    severity: 'medium'
                });
            }
        }

        // Check for duplicate dependencies
        const duplicates = this.findDuplicateDependencies(dependencies);
        duplicates.forEach(dup => {
            issues.push({
                type: 'duplicate_dependency',
                package: dup,
                severity: 'low',
                impact: 'Bundle size increase'
            });
        });

        const nodeVersionCheck = this.checkNodeVersion(packageData);

        return { issues, nodeVersionCheck, recommendations };
    }

    private checkNodeVersion(packageData: any): any {
        const engines = packageData.engines;
        if (!engines || !engines.node) {
            return {
                specified: false,
                recommendation: 'Specify Node.js version in engines field'
            };
        }

        return {
            specified: true,
            requirement: engines.node,
            isSupported: true // Would check against current Node.js version
        };
    }

    private generateInsights(analysis: any): any[] {
        const insights = [];

        // Security insights
        if (analysis.security.riskScore > 0) {
            insights.push({
                type: 'security',
                title: 'Security Risk Assessment',
                message: `Your project has a security risk score of ${analysis.security.riskScore}`,
                priority: analysis.security.riskScore > 10 ? 'high' : 'medium'
            });
        }

        // Maintenance insights
        const outdatedCount = analysis.updates.outdated.length;
        if (outdatedCount > 0) {
            insights.push({
                type: 'maintenance',
                title: 'Package Maintenance',
                message: `${outdatedCount} of your dependencies are outdated`,
                recommendation: 'Regular updates improve security and performance'
            });
        }

        // Best practices
        insights.push({
            type: 'best_practices',
            title: 'Dependency Management Best Practices',
            recommendations: [
                'Pin exact versions for production deployments',
                'Use npm audit regularly to check for vulnerabilities',
                'Keep dependencies up to date',
                'Remove unused dependencies',
                'Use lockfiles (package-lock.json) for consistent installs'
            ]
        });

        return insights;
    }

    // Helper methods
    private cleanVersion(version: string): string {
        return version.replace(/^[\^~]/, '');
    }

    private isVersionAffected(version: string, affectedVersions: string): boolean {
        try {
            return semver.satisfies(version, affectedVersions);
        } catch {
            return false;
        }
    }

    private getUpdateType(current: string, latest: string): string {
        if (semver.major(latest) > semver.major(current)) return 'major';
        if (semver.minor(latest) > semver.minor(current)) return 'minor';
        return 'patch';
    }

    private countVersionsBehind(current: string, latest: string): number {
        const currentParts = current.split('.').map(Number);
        const latestParts = latest.split('.').map(Number);
        
        // Ensure we have at least 3 parts for each version
        while (currentParts.length < 3) currentParts.push(0);
        while (latestParts.length < 3) latestParts.push(0);
        
        return (latestParts[0]! - currentParts[0]!) * 1000 + 
               (latestParts[1]! - currentParts[1]!) * 100 + 
               (latestParts[2]! - currentParts[2]!);
    }

    private findDuplicateDependencies(dependencies: Record<string, string>): string[] {
        // Mock implementation - would analyze package tree for duplicates
        return [];
    }

    private getKnownVulnerabilities(): any[] {
        // Mock vulnerability database - in real implementation, this would query a security database
        return [
            {
                package: 'lodash',
                affectedVersions: '<4.17.19',
                severity: 'high',
                cve: 'CVE-2020-8203',
                description: 'Prototype pollution vulnerability',
                fixedVersion: '4.17.19'
            },
            {
                package: 'minimist',
                affectedVersions: '<1.2.6',
                severity: 'medium',
                cve: 'CVE-2021-44906',
                description: 'Prototype pollution vulnerability',
                fixedVersion: '1.2.6'
            }
        ];
    }

    private getMockLatestVersions(): Record<string, string> {
        // Mock registry data - in real implementation, this would query npm registry
        return {
            'express': '4.18.2',
            'react': '18.2.0',
            'lodash': '4.17.21',
            'axios': '1.6.0',
            'typescript': '5.4.0',
            '@types/node': '20.11.0'
        };
    }
}
