---
name: nuoa-tenant-maven
description: Maven build management for NUOA tenant backend services (Java 11 + Maven 3.x.x)
---

# NUOA Tenant Maven Build Skill

## Description

This skill provides comprehensive Maven build management for the NUOA tenant backend services Java project. It covers compilation, packaging, testing, and verification workflows with the correct Maven and Java versions required by the project.

## Prerequisites

- **Java 11** (JDK 11) - Required by project
- **Maven 3.x.x** (preferably 3.6.0+) - Required for build
- Access to Maven Central and project dependencies
- Sufficient disk space for local Maven repository

## Project Configuration

From [pom.xml](../../../repos/nuoa-io-backend-tenant-services/src/java/lambdas/pom.xml):

- **Java Version**: 11 (`maven.compiler.source` and `maven.compiler.target`)
- **Project**: Tenant Backend Lambda Functions
- **Artifact**: `tenantbackend.jar`
- **Key Dependencies**:
  - AWS SDK 2.34.2
  - AWS Lambda Powertools 2.1.1
  - OpenSearch Java 2.23.0
  - DynamoDB Enhanced Client
  - Dagger 2.56.2 (Dependency Injection)
  - JUnit 5.9.2 (Testing)
  - Mockito 5.4.0 (Mocking)

## Verify Prerequisites

```bash
# Check Java version (should be 11)
java -version

# Check Maven version (should be 3.x.x)
mvn --version

# Expected output:
# Apache Maven 3.8.x or 3.9.x
# Java version: 11.x.x
```

## Common Maven Commands

### Clean and Compile

```bash
cd repos/nuoa-io-backend-tenant-services/src/java/lambdas

# Clean previous builds
mvn clean

# Compile source code
mvn clean compile

# Compile without running tests
mvn clean compile -DskipTests
```

### Package (Build JAR)

```bash
cd repos/nuoa-io-backend-tenant-services/src/java/lambdas

# Build JAR with tests
mvn clean package

# Build JAR without any tests
mvn clean package -DskipTests

# Build JAR skipping only integration tests
mvn clean package -DskipITs

# Build JAR skipping only unit tests
mvn clean package -DskipUTs

# Build JAR skipping both unit and integration tests
mvn clean package -DskipTests -DskipITs -DskipUTs
```

Output: `target/tenantbackend.jar`

### Run Tests

```bash
cd repos/nuoa-io-backend-tenant-services/src/java/lambdas

# Run all tests (unit + integration)
mvn test

# Run only unit tests
mvn test -DskipITs

# Run integration tests (requires Docker for DynamoDB Local and OpenSearch)
mvn verify

# Run integration tests only
mvn verify -DskipUTs

# Run with verbose output
mvn test -X
```

### Verify (Full Build + Tests)

```bash
cd repos/nuoa-io-backend-tenant-services/src/java/lambdas

# Full verification (compile + test + integration test)
mvn verify

# Verify without tests
mvn verify -DskipTests

# Verify with specific test
mvn verify -Dtest=DefaultFormListTest
```

### Install to Local Repository

```bash
cd repos/nuoa-io-backend-tenant-services/src/java/lambdas

# Install to local Maven repository (~/.m2/repository)
mvn clean install

# Install without tests
mvn clean install -DskipTests
```

## Test Configuration

### Test Types

The project uses three test categories:

1. **Unit Tests** (Surefire Plugin)
   - Fast, no external dependencies
   - Mock all external services
   - Run with: `mvn test` or `mvn test -DskipITs`
   - Skip with: `-DskipUTs`

2. **Integration Tests** (Failsafe Plugin)
   - Require Docker containers (DynamoDB Local, OpenSearch)
   - Test actual integrations
   - Run with: `mvn verify`
   - Skip with: `-DskipITs`

3. **Skip All Tests**
   - Use: `-DskipTests` (skips both unit and integration tests)

### Integration Test Environment

Integration tests use Docker containers:

```yaml
Environment Variables:
  DYNAMODB_ENDPOINT_OVERRIDE: http://localhost:8000
  OPEN_SEARCH_ENDPOINT_OVERRIDE: https://localhost:9200
  OPEN_SEARCH_USERNAME: admin
  OPEN_SEARCH_PASSWORD: admin

Docker Containers:
  - DynamoDB Local (port 8000)
  - OpenSearch 2.7.0 (port 9200)
```

Started automatically by `docker-maven-plugin` during `pre-integration-test` phase.

## Build Lifecycle

### Standard Build Flow

```
clean → compile → test → package → verify → install
```

### Phases Explained

1. **clean**: Delete `target/` directory
2. **compile**: Compile `src/main/java`
3. **test**: Run unit tests (Surefire)
4. **package**: Create JAR file
5. **verify**: Run integration tests (Failsafe)
6. **install**: Copy to local Maven repo

## Common Workflows

### Development (Quick Build)

```bash
cd repos/nuoa-io-backend-tenant-services/src/java/lambdas

# Fast build for development
mvn clean compile -DskipTests

# Build JAR quickly
mvn clean package -DskipTests
```

### Testing (with Unit Tests)

```bash
cd repos/nuoa-io-backend-tenant-services/src/java/lambdas

# Build with unit tests only
mvn clean package -DskipITs

# Just run tests
mvn test
```

### Full Build (with All Tests)

```bash
cd repos/nuoa-io-backend-tenant-services/src/java/lambdas

# Complete build with all tests
mvn clean verify

# Complete build and install locally
mvn clean install
```

### CI/CD Pipeline Build

```bash
cd repos/nuoa-io-backend-tenant-services/src/java/lambdas

# Typical CI build (no tests for speed)
mvn clean package -DskipTests

# CI build with unit tests
mvn clean package -DskipITs

# Full CI verification
mvn clean verify
```

### Debugging Build Issues

```bash
cd repos/nuoa-io-backend-tenant-services/src/java/lambdas

# Verbose output
mvn clean compile -X

# Debug specific test
mvn test -Dtest=DefaultFormListTest -X

# Check dependency tree
mvn dependency:tree

# Check for dependency conflicts
mvn dependency:analyze
```

## Code Quality

### Spotless (Code Formatting)

The project uses Spotless for code formatting with Eclipse formatter:

```bash
# Check formatting
mvn spotless:check

# Apply formatting
mvn spotless:apply
```

Runs automatically during `verify` goal.

### Lombok Support

The project uses Lombok for reducing boilerplate:
- Requires AspectJ weaving
- Automatically handled by `aspectj-maven-plugin`

## Build Optimization

### Speed Tips

1. **Skip Tests During Development**
   ```bash
   mvn clean package -DskipTests
   ```

2. **Offline Mode** (use cached dependencies)
   ```bash
   mvn clean package -o
   ```

3. **Multi-threaded Build**
   ```bash
   mvn clean package -T 4  # 4 threads
   mvn clean package -T 1C # 1 thread per CPU core
   ```

4. **Skip Unnecessary Plugins**
   ```bash
   mvn clean package -DskipTests -Dspotless.check.skip=true
   ```

### Dependency Management

```bash
# Update dependencies
mvn versions:display-dependency-updates

# Update plugins
mvn versions:display-plugin-updates

# Download all dependencies
mvn dependency:go-offline

# Clean local repository cache
rm -rf ~/.m2/repository/cdk-sample/TenantBackend
```

## Troubleshooting

### "JAVA_HOME is not set"

```bash
# Set JAVA_HOME to JDK 11
export JAVA_HOME=/path/to/jdk-11
export PATH=$JAVA_HOME/bin:$PATH

# Verify
java -version
```

### "Maven version is too old"

```bash
# Check version
mvn --version

# Upgrade Maven to 3.8+
# Download from: https://maven.apache.org/download.cgi
```

### "Cannot find symbol" compilation errors

```bash
# Clean and rebuild
mvn clean compile

# Check Lombok is working
# Verify annotation processing is enabled in IDE
```

### "Tests are not running"

```bash
# Check test configuration
mvn test -X

# Ensure test class names follow convention:
# *Test.java for unit tests
# *IT.java for integration tests
```

### "OutOfMemoryError during build"

```bash
# Increase Maven memory
export MAVEN_OPTS="-Xmx2048m -XX:MaxPermSize=512m"

# Or set in .mavenrc file
echo "MAVEN_OPTS=\"-Xmx2048m\"" > ~/.mavenrc
```

### "Docker containers not starting for integration tests"

```bash
# Check Docker is running
docker ps

# Check ports are available
lsof -i :8000  # DynamoDB Local
lsof -i :9200  # OpenSearch

# Manual cleanup
docker stop $(docker ps -aq)
docker rm $(docker ps -aq)
```

### "Dependency download failures"

```bash
# Clear corrupted downloads
rm -rf ~/.m2/repository

# Retry download
mvn clean compile -U  # Force update

# Use different mirror in ~/.m2/settings.xml
```

## Integration with Other Skills

### With nuoa-update-lambda

```bash
# Build and deploy
cd repos/nuoa-io-backend-tenant-services/src/java/lambdas
mvn clean package -DskipTests

cd ../../../..  # Back to repo root
bash .github/skills/nuoa-update-lambda/update_lambda.sh \
  --profile aws-beta \
  --query Activity \
  --all
```

### With nuoa-fix-opensearch

```bash
# Generate index mappings
cd repos/nuoa-io-backend-tenant-services/src/java/lambdas
mvn test -Dtest=DefaultFormListTest#generateFieldTypesFile

# Fix OpenSearch domain
cd ../../../..
python .github/skills/nuoa-fix-opensearch/fix_opensearch_domain.py \
  --profile nuoa-beta
```

### With CI/CD Pipeline

```yaml
# Typical pipeline steps
- name: Build
  run: |
    cd repos/nuoa-io-backend-tenant-services/src/java/lambdas
    mvn clean package -DskipITs

- name: Test
  run: |
    cd repos/nuoa-io-backend-tenant-services/src/java/lambdas
    mvn verify
```

## Maven Profiles

The project doesn't define custom profiles, but you can use standard Maven behavior:

```bash
# Skip tests globally
mvn clean package -DskipTests=true

# Skip only integration tests
mvn clean package -DskipITs=true

# Skip only unit tests
mvn clean package -DskipUTs=true
```

## Output Files

### Build Artifacts

```
target/
├── tenantbackend.jar          # Shaded JAR (all dependencies)
├── classes/                   # Compiled classes
├── generated-sources/         # Generated code (Dagger)
├── test-classes/              # Compiled test classes
├── surefire-reports/          # Unit test reports
└── failsafe-reports/          # Integration test reports
```

### Generated JAR

- **Name**: `tenantbackend.jar`
- **Location**: `target/tenantbackend.jar`
- **Type**: Shaded JAR (uber-jar with all dependencies)
- **Size**: ~60-80 MB
- **Used by**: AWS Lambda functions

## Dependencies Overview

### AWS SDK
- DynamoDB Enhanced Client
- S3, SQS, STS, Secrets Manager
- Lambda client

### AWS Lambda
- Lambda Java Core
- Lambda Java Events
- Powertools (Logging, Tracing)

### Search
- OpenSearch Java Client 2.23.0

### Testing
- JUnit 5.9.2
- Mockito 5.4.0
- AssertJ 3.24.2

### Utilities
- Lombok 1.18.28
- Dagger 2.56.2
- Handlebars 4.3.1
- CEL (Common Expression Language) 0.9.0

## Best Practices

1. **Always use clean builds for releases**
   ```bash
   mvn clean package
   ```

2. **Run tests before committing**
   ```bash
   mvn verify
   ```

3. **Format code before committing**
   ```bash
   mvn spotless:apply
   ```

4. **Check dependencies periodically**
   ```bash
   mvn versions:display-dependency-updates
   ```

5. **Use offline mode for repeated builds**
   ```bash
   mvn -o package -DskipTests
   ```

## Quick Reference

| Command | Purpose | Tests |
|---------|---------|-------|
| `mvn clean` | Delete build artifacts | N/A |
| `mvn compile` | Compile source code | No |
| `mvn test` | Run unit tests | Unit only |
| `mvn package` | Build JAR | Unit only |
| `mvn verify` | Full build + integration tests | All |
| `mvn install` | Install to local repo | All |
| `mvn package -DskipTests` | Quick JAR build | None |
| `mvn package -DskipITs` | JAR with unit tests | Unit only |
| `mvn verify -DskipUTs` | Integration tests only | Integration only |

## Environment Setup

### Recommended IDE Settings

**IntelliJ IDEA:**
- Enable annotation processing
- Install Lombok plugin
- Set JDK to Java 11
- Set Maven home to 3.8+

**VS Code:**
- Install Extension Pack for Java
- Install Lombok Annotations Support
- Configure java.configuration.runtimes for Java 11

### Maven Settings

Create `~/.m2/settings.xml`:

```xml
<settings>
  <profiles>
    <profile>
      <id>default</id>
      <properties>
        <maven.compiler.source>11</maven.compiler.source>
        <maven.compiler.target>11</maven.compiler.target>
      </properties>
    </profile>
  </profiles>
  <activeProfiles>
    <activeProfile>default</activeProfile>
  </activeProfiles>
</settings>
```

## Related Files

- **pom.xml**: [repos/nuoa-io-backend-tenant-services/src/java/lambdas/pom.xml](../../../repos/nuoa-io-backend-tenant-services/src/java/lambdas/pom.xml)
- **Source**: [repos/nuoa-io-backend-tenant-services/src/java/lambdas/src/main/java/](../../../repos/nuoa-io-backend-tenant-services/src/java/lambdas/src/main/java/)
- **Tests**: [repos/nuoa-io-backend-tenant-services/src/java/lambdas/src/test/java/](../../../repos/nuoa-io-backend-tenant-services/src/java/lambdas/src/test/java/)
- **Resources**: [repos/nuoa-io-backend-tenant-services/src/java/lambdas/src/main/resources/](../../../repos/nuoa-io-backend-tenant-services/src/java/lambdas/src/main/resources/)

## Related Skills

- **nuoa-update-lambda**: Deploy built JARs to Lambda functions
- **nuoa-fix-opensearch**: Fix OpenSearch configurations (uses Maven tests)
- **java-best-practices**: Java coding standards
- **testing-strategies**: Testing approaches
- **ci-cd-design**: Pipeline design patterns

---

**Version Requirements:**
- Java: 11
- Maven: 3.x.x (3.6.0+ recommended)
- Docker: Latest (for integration tests)

**Build Time:**
- Quick build (no tests): ~30-60 seconds
- With unit tests: ~2-5 minutes
- Full verification: ~5-10 minutes

**JAR Size:** ~60-80 MB (shaded with all dependencies)
