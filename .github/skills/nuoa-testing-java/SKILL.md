---
name: nuoa-testing-java
description: Comprehensive testing strategies for Java 11 Lambda handlers with unit testing, integration testing, and mocking
---

# NUOA Java Testing Strategy

## Description

This skill defines comprehensive testing strategies for Java 11 Lambda handlers and business logic in NUOA's tenant services. It covers unit testing, integration testing, mocking strategies, and test organization following DDD principles.

## Testing Framework

### Core Dependencies

```xml
<!-- JUnit 5 (Jupiter) -->
<dependency>
    <groupId>org.junit.jupiter</groupId>
    <artifactId>junit-jupiter-api</artifactId>
    <version>5.9.3</version>
    <scope>test</scope>
</dependency>
<dependency>
    <groupId>org.junit.jupiter</groupId>
    <artifactId>junit-jupiter-engine</artifactId>
    <version>5.9.3</version>
    <scope>test</scope>
</dependency>

<!-- Mockito -->
<dependency>
    <groupId>org.mockito</groupId>
    <artifactId>mockito-core</artifactId>
    <version>5.3.1</version>
    <scope>test</scope>
</dependency>
<dependency>
    <groupId>org.mockito</groupId>
    <artifactId>mockito-junit-jupiter</artifactId>
    <version>5.3.1</version>
    <scope>test</scope>
</dependency>

<!-- AssertJ (fluent assertions) -->
<dependency>
    <groupId>org.assertj</groupId>
    <artifactId>assertj-core</artifactId>
    <version>3.24.2</version>
    <scope>test</scope>
</dependency>
```

## Test Structure

### Package Organization

```
src/test/java/io/nuoa/
├── domain/
│   ├── model/
│   │   └── ActivityTest.java
│   └── service/
│       └── ActivityDomainServiceTest.java
├── application/
│   ├── handler/
│   │   └── ActivityGetHandlerTest.java
│   └── usecase/
│       └── GetActivityUseCaseTest.java
└── infrastructure/
    ├── dynamodb/
    │   └── DynamoDBActivityRepositoryTest.java
    └── IntegrationTestBase.java
```

## Unit Testing Patterns

### Lambda Handler Test

```java
package io.nuoa.application.handler;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.events.APIGatewayProxyRequestEvent;
import com.amazonaws.services.lambda.runtime.events.APIGatewayProxyResponseEvent;
import io.nuoa.domain.model.Activity;
import io.nuoa.domain.repository.ActivityRepository;
import io.nuoa.common.exception.NotFoundException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Map;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("ActivityGetHandler Tests")
class ActivityGetHandlerTest {
    
    @Mock
    private ActivityRepository mockRepository;
    
    @Mock
    private Context mockContext;
    
    private ActivityGetHandler handler;
    
    @BeforeEach
    void setUp() {
        handler = new ActivityGetHandler(mockRepository);
    }
    
    @Test
    @DisplayName("Should return 200 with activity when found")
    void shouldReturnActivityWhenFound() {
        // Given
        String tenantId = "tenant-123";
        String activityId = "activity-456";
        
        Activity expectedActivity = new Activity();
        expectedActivity.setTenantId(tenantId);
        expectedActivity.setActivityId(activityId);
        expectedActivity.setName("Office Electricity");
        
        when(mockRepository.findById(eq(tenantId), eq(activityId)))
            .thenReturn(Optional.of(expectedActivity));
        
        APIGatewayProxyRequestEvent request = createRequest(tenantId, activityId);
        
        // When
        APIGatewayProxyResponseEvent response = handler.handleRequest(request, mockContext);
        
        // Then
        assertThat(response.getStatusCode()).isEqualTo(200);
        assertThat(response.getBody()).contains("Office Electricity");
        verify(mockRepository, times(1)).findById(tenantId, activityId);
    }
    
    @Test
    @DisplayName("Should return 404 when activity not found")
    void shouldReturn404WhenNotFound() {
        // Given
        String tenantId = "tenant-123";
        String activityId = "nonexistent";
        
        when(mockRepository.findById(eq(tenantId), eq(activityId)))
            .thenReturn(Optional.empty());
        
        APIGatewayProxyRequestEvent request = createRequest(tenantId, activityId);
        
        // When
        APIGatewayProxyResponseEvent response = handler.handleRequest(request, mockContext);
        
        // Then
        assertThat(response.getStatusCode()).isEqualTo(404);
        assertThat(response.getBody()).contains("not found");
    }
    
    @Test
    @DisplayName("Should return 500 when repository throws exception")
    void shouldReturn500OnRepositoryError() {
        // Given
        String tenantId = "tenant-123";
        String activityId = "activity-456";
        
        when(mockRepository.findById(eq(tenantId), eq(activityId)))
            .thenThrow(new RuntimeException("Database connection failed"));
        
        APIGatewayProxyRequestEvent request = createRequest(tenantId, activityId);
        
        // When
        APIGatewayProxyResponseEvent response = handler.handleRequest(request, mockContext);
        
        // Then
        assertThat(response.getStatusCode()).isEqualTo(500);
    }
    
    private APIGatewayProxyRequestEvent createRequest(String tenantId, String activityId) {
        APIGatewayProxyRequestEvent request = new APIGatewayProxyRequestEvent();
        request.setPathParameters(Map.of(
            "tenantId", tenantId,
            "id", activityId
        ));
        return request;
    }
}
```

### Domain Model Test

```java
package io.nuoa.domain.model;

import io.nuoa.common.exception.ValidationException;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.NullAndEmptySource;
import org.junit.jupiter.params.provider.ValueSource;

import static org.assertj.core.api.Assertions.*;

@DisplayName("Activity Domain Model Tests")
class ActivityTest {
    
    @Test
    @DisplayName("Should create activity with valid data")
    void shouldCreateActivityWithValidData() {
        // Given & When
        Activity activity = new Activity.Builder()
            .tenantId("tenant-123")
            .activityId("activity-456")
            .name("Office Electricity")
            .type(ActivityType.ENERGY)
            .build();
        
        // Then
        assertThat(activity.getTenantId()).isEqualTo("tenant-123");
        assertThat(activity.getName()).isEqualTo("Office Electricity");
        assertThat(activity.getType()).isEqualTo(ActivityType.ENERGY);
        assertThat(activity.getVersionId()).isEqualTo(0L);
    }
    
    @ParameterizedTest
    @NullAndEmptySource
    @ValueSource(strings = {"  ", "\t", "\n"})
    @DisplayName("Should throw exception when name is blank")
    void shouldThrowExceptionWhenNameIsBlank(String invalidName) {
        // Given
        Activity activity = new Activity();
        
        // When & Then
        assertThatThrownBy(() -> activity.updateName(invalidName))
            .isInstanceOf(ValidationException.class)
            .hasMessageContaining("cannot be empty");
    }
    
    @Test
    @DisplayName("Should increment version on update")
    void shouldIncrementVersionOnUpdate() {
        // Given
        Activity activity = new Activity();
        activity.setVersionId(5L);
        
        // When
        activity.updateName("New Name");
        
        // Then
        assertThat(activity.getVersionId()).isEqualTo(6L);
        assertThat(activity.getName()).isEqualTo("New Name");
    }
    
    @Test
    @DisplayName("Should set updatedAt timestamp on update")
    void shouldSetUpdatedAtOnUpdate() {
        // Given
        Activity activity = new Activity();
        activity.setUpdatedAt(null);
        
        // When
        activity.updateName("New Name");
        
        // Then
        assertThat(activity.getUpdatedAt()).isNotNull();
    }
}
```

### Repository Test (with DynamoDB Local)

```java
package io.nuoa.infrastructure.dynamodb;

import com.amazonaws.services.dynamodbv2.AmazonDynamoDB;
import com.amazonaws.services.dynamodbv2.datamodeling.DynamoDBMapper;
import com.amazonaws.services.dynamodbv2.local.embedded.DynamoDBEmbedded;
import com.amazonaws.services.dynamodbv2.model.*;
import io.nuoa.domain.model.Activity;
import io.nuoa.domain.model.ActivityType;
import org.junit.jupiter.api.*;

import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;

@DisplayName("DynamoDB Activity Repository Tests")
class DynamoDBActivityRepositoryTest {
    
    private static AmazonDynamoDB dynamoDb;
    private DynamoDBActivityRepository repository;
    private DynamoDBMapper mapper;
    
    @BeforeAll
    static void setUpClass() {
        // Start DynamoDB Local
        System.setProperty("sqlite4java.library.path", "native-libs");
        dynamoDb = DynamoDBEmbedded.create().amazonDynamoDB();
    }
    
    @BeforeEach
    void setUp() {
        // Create table
        createActivityTable();
        
        // Initialize repository
        mapper = new DynamoDBMapper(dynamoDb);
        repository = new DynamoDBActivityRepository(mapper);
    }
    
    @AfterEach
    void tearDown() {
        // Clean up table
        dynamoDb.deleteTable("Activity");
    }
    
    @Test
    @DisplayName("Should save and retrieve activity")
    void shouldSaveAndRetrieveActivity() {
        // Given
        Activity activity = createTestActivity("tenant-123", "activity-456");
        
        // When
        repository.save(activity);
        Optional<Activity> retrieved = repository.findById("tenant-123", "activity-456");
        
        // Then
        assertThat(retrieved).isPresent();
        assertThat(retrieved.get().getName()).isEqualTo("Test Activity");
        assertThat(retrieved.get().getType()).isEqualTo(ActivityType.ENERGY);
    }
    
    @Test
    @DisplayName("Should return empty when activity not found")
    void shouldReturnEmptyWhenNotFound() {
        // When
        Optional<Activity> result = repository.findById("tenant-123", "nonexistent");
        
        // Then
        assertThat(result).isEmpty();
    }
    
    @Test
    @DisplayName("Should find all activities by tenant")
    void shouldFindAllByTenant() {
        // Given
        Activity activity1 = createTestActivity("tenant-123", "activity-1");
        Activity activity2 = createTestActivity("tenant-123", "activity-2");
        Activity activity3 = createTestActivity("tenant-456", "activity-3");
        
        repository.save(activity1);
        repository.save(activity2);
        repository.save(activity3);
        
        // When
        List<Activity> results = repository.findByTenantId("tenant-123");
        
        // Then
        assertThat(results).hasSize(2);
        assertThat(results).extracting("activityId")
            .containsExactlyInAnyOrder("activity-1", "activity-2");
    }
    
    private void createActivityTable() {
        CreateTableRequest request = new CreateTableRequest()
            .withTableName("Activity")
            .withKeySchema(
                new KeySchemaElement("tenantId", KeyType.HASH),
                new KeySchemaElement("activityId", KeyType.RANGE)
            )
            .withAttributeDefinitions(
                new AttributeDefinition("tenantId", ScalarAttributeType.S),
                new AttributeDefinition("activityId", ScalarAttributeType.S)
            )
            .withProvisionedThroughput(new ProvisionedThroughput(5L, 5L));
        
        dynamoDb.createTable(request);
    }
    
    private Activity createTestActivity(String tenantId, String activityId) {
        return new Activity.Builder()
            .tenantId(tenantId)
            .activityId(activityId)
            .name("Test Activity")
            .type(ActivityType.ENERGY)
            .build();
    }
}
```

## Test Categories

### Fast Tests (Unit Tests)

```java
@Tag("unit")
@Tag("fast")
class ActivityGetHandlerTest {
    // Tests that run quickly without external dependencies
}

// Run with: mvn test -Dgroups="fast"
```

### Slow Tests (Integration Tests)

```java
@Tag("integration")
@Tag("slow")
class DynamoDBActivityRepositoryTest {
    // Tests that require external resources
}

// Run with: mvn test -Dgroups="slow"
```

## Test Fixtures and Builders

### Test Data Builder

```java
public class ActivityTestBuilder {
    private String tenantId = "test-tenant";
    private String activityId = "test-activity";
    private String name = "Test Activity";
    private ActivityType type = ActivityType.ENERGY;
    private Long versionId = 0L;
    
    public ActivityTestBuilder withTenantId(String tenantId) {
        this.tenantId = tenantId;
        return this;
    }
    
    public ActivityTestBuilder withActivityId(String activityId) {
        this.activityId = activityId;
        return this;
    }
    
    public ActivityTestBuilder withName(String name) {
        this.name = name;
        return this;
    }
    
    public ActivityTestBuilder withType(ActivityType type) {
        this.type = type;
        return this;
    }
    
    public Activity build() {
        return new Activity.Builder()
            .tenantId(tenantId)
            .activityId(activityId)
            .name(name)
            .type(type)
            .build();
    }
}

// Usage in tests
Activity activity = new ActivityTestBuilder()
    .withTenantId("tenant-123")
    .withName("Custom Activity")
    .build();
```

## Mocking Strategies

### When to Mock

- **Mock**: External dependencies (AWS services, HTTP clients)
- **Don't Mock**: Value objects, domain models, DTOs
- **Sometimes Mock**: Repositories (unit tests: yes, integration tests: no)

### Mockito Best Practices

```java
// Good: Specific argument matchers
when(mockRepository.findById(eq("tenant-123"), eq("activity-456")))
    .thenReturn(Optional.of(activity));

// Avoid: Any matchers (too permissive)
when(mockRepository.findById(any(), any()))
    .thenReturn(Optional.of(activity));

// Good: Verify specific interactions
verify(mockRepository, times(1)).findById("tenant-123", "activity-456");

// Good: Verify no other interactions
verifyNoMoreInteractions(mockRepository);
```

## Assertions

### AssertJ Fluent Assertions

```java
// Basic assertions
assertThat(response.getStatusCode()).isEqualTo(200);
assertThat(activity.getName()).isNotNull().startsWith("Office");
assertThat(activities).hasSize(3).extracting("name")
    .containsExactly("Activity 1", "Activity 2", "Activity 3");

// Exception assertions
assertThatThrownBy(() -> activity.updateName(null))
    .isInstanceOf(ValidationException.class)
    .hasMessage("Name cannot be null")
    .hasNoCause();

// Collection assertions
assertThat(activities)
    .isNotEmpty()
    .hasSize(2)
    .extracting("type")
    .containsOnly(ActivityType.ENERGY);
```

## Test Coverage

### Minimum Requirements

- **Line Coverage**: 80%
- **Branch Coverage**: 75%
- **Critical Paths**: 100%

### JaCoCo Configuration

```xml
<plugin>
    <groupId>org.jacoco</groupId>
    <artifactId>jacoco-maven-plugin</artifactId>
    <version>0.8.10</version>
    <configuration>
        <rules>
            <rule>
                <element>BUNDLE</element>
                <limits>
                    <limit>
                        <counter>LINE</counter>
                        <value>COVEREDRATIO</value>
                        <minimum>0.80</minimum>
                    </limit>
                </limits>
            </rule>
        </rules>
    </configuration>
</plugin>
```

## Integration Testing

### LocalStack for AWS Services

```java
@Testcontainers
class IntegrationTest {
    
    @Container
    static LocalStackContainer localstack = new LocalStackContainer(DockerImageName.parse("localstack/localstack:latest"))
        .withServices(LocalStackContainer.Service.DYNAMODB);
    
    private static AmazonDynamoDB dynamoDb;
    
    @BeforeAll
    static void setUp() {
        dynamoDb = AmazonDynamoDBClientBuilder.standard()
            .withEndpointConfiguration(localstack.getEndpointConfiguration(LocalStackContainer.Service.DYNAMODB))
            .withCredentials(localstack.getDefaultCredentialsProvider())
            .build();
    }
}
```

## Test Naming Conventions

### Test Method Names

```java
// Pattern: should_ExpectedBehavior_When_StateUnderTest

@Test
void should_ReturnActivity_When_ActivityExists() { }

@Test
void should_ThrowNotFoundException_When_ActivityDoesNotExist() { }

@Test
void should_IncrementVersion_When_ActivityIsUpdated() { }
```

## Related Skills

- [nuoa-java11](../nuoa-java11/SKILL.md): Java development patterns
- [domain-driven-design](../domain-driven-design/SKILL.md): DDD principles
- [testing](../testing/SKILL.md): General testing strategies
- [nuoa-testing-python](../nuoa-testing-python/SKILL.md): Python testing patterns
