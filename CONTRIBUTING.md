# Contributing to the MCP Server Workshop

We welcome contributions to make this workshop even better! This guide will help you contribute effectively.

## Ways to Contribute

### 📝 Documentation
- Improve existing documentation
- Add new examples and use cases
- Translate documentation to other languages
- Fix typos and improve clarity

### 🔧 Code Improvements
- Bug fixes and performance improvements
- New MCP tools and features
- Better error handling and logging
- Infrastructure and deployment enhancements

### 🧪 Testing
- Add test cases for existing tools
- Integration testing scenarios
- Performance testing
- Security testing

### 💡 Ideas and Feedback
- Suggest new workshop modules
- Propose new MCP tools
- Share your workshop experience
- Report issues and bugs

## Getting Started

### 1. Fork and Clone

```bash
# Fork the repository on GitHub
# Then clone your fork
git clone https://github.com/YOUR-USERNAME/serverless-mcp-on-functions.git
cd serverless-mcp-on-functions

# Add upstream remote
git remote add upstream https://github.com/original-repo/serverless-mcp-on-functions.git
```

### 2. Set Up Development Environment

```bash
# Install dependencies
npm install

# Set up environment
cp .env.example .env
# Edit .env with your settings

# Build the project
npm run build

# Run tests
npm test
```

### 3. Create a Branch

```bash
# Create a new branch for your contribution
git checkout -b feature/your-feature-name

# Or for bug fixes
git checkout -b fix/issue-description
```

## Development Guidelines

### Code Style

We use TypeScript with strict type checking. Please follow these guidelines:

```typescript
// ✅ Good: Use descriptive names and proper typing
interface ToolResult {
    success: boolean;
    data: any;
    errors?: string[];
}

async function analyzeContent(content: string): Promise<ToolResult> {
    // Implementation here
}

// ❌ Avoid: Unclear names and any types
function doStuff(x: any): any {
    // Implementation here
}
```

### Tool Development Standards

When creating new MCP tools:

1. **Implement the MCPTool interface**:
```typescript
export class MyTool implements MCPTool {
    name = 'my_tool';
    description = 'Clear description of what this tool does';
    
    parameters = {
        input: {
            type: 'string',
            description: 'Description of this parameter'
        }
    };

    constructor(private logger: Logger) {}

    async execute(args: Record<string, any>): Promise<any> {
        // Implementation
    }
}
```

2. **Include comprehensive error handling**:
```typescript
async execute(args: Record<string, any>): Promise<any> {
    try {
        // Validate inputs
        if (!args.input || typeof args.input !== 'string') {
            throw new Error('Input parameter is required and must be a string');
        }

        // Tool logic here
        const result = await this.performAnalysis(args.input);
        
        this.logger.info('Tool execution successful', { 
            toolName: this.name,
            inputSize: args.input.length 
        });
        
        return result;
        
    } catch (error) {
        this.logger.error('Tool execution failed', { 
            toolName: this.name,
            error: error.message 
        });
        throw error;
    }
}
```

3. **Add comprehensive tests**:
```typescript
// tests/tools/my-tool.test.ts
describe('MyTool', () => {
    let tool: MyTool;
    let mockLogger: jest.Mocked<Logger>;

    beforeEach(() => {
        mockLogger = createMockLogger();
        tool = new MyTool(mockLogger);
    });

    it('should execute successfully with valid input', async () => {
        const result = await tool.execute({ input: 'test content' });
        expect(result).toBeDefined();
    });

    it('should throw error with invalid input', async () => {
        await expect(tool.execute({})).rejects.toThrow();
    });
});
```

### Documentation Standards

- Use clear, actionable language
- Include code examples for all features
- Add screenshots for UI-related changes
- Update the main README if adding new features

### Testing Requirements

All contributions should include appropriate tests:

```bash
# Run all tests
npm test

# Run tests in watch mode
npm run test:watch

# Run tests with coverage
npm run test:coverage
```

### Commit Message Format

Use conventional commit messages:

```
type(scope): description

Examples:
feat(tools): add code quality analysis tool
fix(server): handle malformed JSON requests
docs(readme): update installation instructions
test(tools): add tests for markdown review tool
```

Types:
- `feat`: New features
- `fix`: Bug fixes
- `docs`: Documentation updates
- `test`: Test additions/updates
- `refactor`: Code refactoring
- `perf`: Performance improvements
- `chore`: Maintenance tasks

## Contribution Process

### 1. Before You Start

- Check existing issues and pull requests
- Create an issue to discuss major changes
- Ensure your idea aligns with project goals

### 2. Development Workflow

1. **Write Code**: Follow the guidelines above
2. **Test**: Ensure all tests pass
3. **Document**: Update relevant documentation
4. **Commit**: Use conventional commit messages

### 3. Pull Request Process

1. **Update your branch**:
```bash
git fetch upstream
git rebase upstream/main
```

2. **Create pull request** with:
   - Clear title and description
   - Reference to related issues
   - Screenshots for UI changes
   - Test results

3. **Respond to feedback** promptly and professionally

## Specific Contribution Areas

### Adding New MCP Tools

Great tool ideas include:
- **Code Quality Tools**: ESLint, Prettier, SonarQube integration
- **Security Tools**: SAST, DAST, container scanning
- **Performance Tools**: Bundle analysis, performance testing
- **DevOps Tools**: CI/CD integration, deployment checks
- **AI/ML Tools**: Model validation, data quality checks

Template for new tools:
```typescript
// src/tools/your-tool.ts
import { MCPTool } from '../mcp/server';
import { Logger } from '../shared/logger';

export class YourTool implements MCPTool {
    name = 'your_tool';
    description = 'What your tool does';
    
    parameters = {
        // Define parameters
    };

    constructor(private logger: Logger) {}

    async execute(args: Record<string, any>): Promise<any> {
        // Implementation
    }
}
```

### Improving Infrastructure

Areas for improvement:
- **Monitoring**: Enhanced Application Insights dashboards
- **Security**: API authentication, rate limiting
- **Performance**: Caching, connection pooling
- **Deployment**: CI/CD pipelines, multi-region deployment

### Workshop Content

Help make the workshop better:
- **New Scenarios**: Real-world use cases
- **Advanced Topics**: Custom authentication, monitoring
- **Troubleshooting**: Common issues and solutions
- **Video Content**: Recorded walkthroughs

## Code Review Guidelines

### For Contributors

- Keep pull requests focused and small
- Include tests for all new functionality
- Update documentation for any user-facing changes
- Respond to feedback constructively

### For Reviewers

- Be constructive and helpful in feedback
- Focus on code quality, security, and maintainability
- Test the changes locally when possible
- Approve when ready, request changes when needed

## Release Process

1. **Version Bump**: Update version in package.json
2. **Changelog**: Update CHANGELOG.md with new features
3. **Tag Release**: Create git tag and GitHub release
4. **Deploy**: Update workshop examples and documentation

## Community Guidelines

### Be Respectful
- Use inclusive language
- Be patient with newcomers
- Provide constructive feedback
- Assume good intentions

### Stay Focused
- Keep discussions on-topic
- Use appropriate channels for different types of discussions
- Search before asking questions

### Help Others
- Answer questions when you can
- Share your experiences
- Contribute to documentation
- Welcome newcomers

## Getting Help

### Documentation
- Workshop documentation in `docs/`
- Code examples in `examples/`
- API documentation in source code

### Communication
- GitHub Issues for bugs and feature requests
- GitHub Discussions for questions and ideas
- Create an issue for clarification on contribution guidelines

### Development Help
- Check existing issues for similar problems
- Include minimal reproduction steps
- Provide environment details (Node.js version, OS, etc.)

## Recognition

Contributors will be:
- Listed in the contributors section
- Mentioned in release notes for significant contributions
- Invited to become maintainers for consistent, quality contributions

## License

By contributing, you agree that your contributions will be licensed under the same license as the project (MIT License).

---

Thank you for contributing to the MCP Server Workshop! Your contributions help make AI-assisted development more accessible and powerful for everyone.

## Quick Start Checklist

- [ ] Fork and clone the repository
- [ ] Set up development environment
- [ ] Create a feature branch
- [ ] Make your changes following the guidelines
- [ ] Add tests for new functionality
- [ ] Update documentation
- [ ] Submit a pull request
- [ ] Respond to code review feedback

Ready to contribute? Start by checking out our [good first issues](https://github.com/your-repo/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22)!
