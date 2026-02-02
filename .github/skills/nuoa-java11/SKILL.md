---
name: nuoa-java11
description: Best practices, patterns, and conventions for Java 11 development in NUOA's serverless backend services
---

# NUOA Java 11 Development Skill

## Description

This skill defines best practices, patterns, and conventions for Java 11 development in NUOA's serverless backend services. It covers Lambda handler development, DDD patterns, AWS SDK usage, and Java-specific considerations for the NUOA platform.

## Language Version

**Java 11** (LTS) - Used across all NUOA backend services
- Lambda runtime: `java11`
- Maven compiler target: `11`
- Source/target compatibility: `11`

## Project Structure

### Maven Configuration

```xml
<properties>
    <maven.compiler.source>11</maven.compiler.source>
    <maven.compiler.target>11</maven.compiler.target>
    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
</properties>
```

### Package Organization (DDD)

```
src/main/java/io/nuoa/
├── domain/           # Domain layer
│   ├── model/       # Entities, Value Objects, Aggregates
│   ├── repository/  # Repository interfaces
│   └── service/     # Domain services
├── application/     # Application layer
│   ├── handler/    # Lambda handlers
│   ├── usecase/    # Use cases/Application services
│   └── dto/        # Data Transfer Objects
├── infrastructure/  # Infrastructure layer
│   ├── dynamodb/   # DynamoDB implementations
│   ├── opensearch/ # OpenSearch implementations
│   └── sqs/        # SQS implementations
└── common/         # Shared utilities
    ├── exception/  # Custom exceptions
    ├── util/       # Utility classes
    └── constant/   # Constants
```

## AWS Lambda Handler Pattern

### Standard Handler Structure

```java
public class ActivityGetHandler implements RequestHandler<APIGatewayProxyRequestEvent, APIGatewayProxyResponseEvent> {
    
    private final ActivityRepository repository;
    private final ObjectMapper objectMapper;
    
    // Constructor for dependency injection
    public ActivityGetHandler() {
        this.repository = new DynamoDBActivityRepository();
        this.objectMapper = new ObjectMapper();
    }
    
    // Constructor for testing
    public ActivityGetHandler(ActivityRepository repository, ObjectMapper objectMapper) {
        this.repository = repository;
        this.objectMapper = objectMapper;
    }
    
    @Override
    public APIGatewayProxyResponseEvent handleRequest(APIGatewayProxyRequestEvent input, Context context) {
        try {
            // 1. Extract parameters
            String tenantId = input.getPathParameters().get("tenantId");
            String activityId = input.getPathParameters().get("id");
            
            // 2. Validate input
            validateInput(tenantId, activityId);
            
            // 3. Execute business logic
            Activity activity = repository.findById(tenantId, activityId)
                .orElseThrow(() -> new NotFoundException("Activity not found"));
            
            // 4. Return response
            return buildSuccessResponse(activity);
            
        } catch (NotFoundException e) {
            return buildErrorResponse(404, e.getMessage());
        } catch (ValidationException e) {
            return buildErrorResponse(400, e.getMessage());
        } catch (Exception e) {
            context.getLogger().log("Error: " + e.getMessage());
            return buildErrorResponse(500, "Internal server error");
        }
    }
    
    private APIGatewayProxyResponseEvent buildSuccessResponse(Object body) {
        return new APIGatewayProxyResponseEvent()
            .withStatusCode(200)
            .withHeaders(getCorsHeaders())
            .withBody(toJson(body));
    }
}
```

## Domain-Driven Design Patterns

### Entity with Optimistic Locking

```java
@DynamoDBTable(tableName = "Activity")
public class Activity {
    
    private String tenantId;
    private String activityId;
    private String name;
    private ActivityType type;
    private Long versionId;
    private Instant createdAt;
    private Instant updatedAt;
    
    @DynamoDBHashKey(attributeName = "tenantId")
    public String getTenantId() { return tenantId; }
    
    @DynamoDBRangeKey(attributeName = "activityId")
    public String getActivityId() { return activityId; }
    
    @DynamoDBAttribute(attributeName = "versionId")
    @DynamoDBVersionAttribute
    public Long getVersionId() { return versionId; }
    
    // Business logic methods
    public void updateName(String newName) {
        if (newName == null || newName.trim().isEmpty()) {
            throw new ValidationException("Activity name cannot be empty");
        }
        this.name = newName;
        this.updatedAt = Instant.now();
        this.versionId++;
    }
}
```

### Value Object

```java
public class CarbonFootprint {
    private final double amount;
    private final String unit;
    
    public CarbonFootprint(double amount, String unit) {
        if (amount < 0) {
            throw new ValidationException("Carbon footprint cannot be negative");
        }
        this.amount = amount;
        this.unit = unit;
    }
    
    // Value objects are immutable
    public double getAmount() { return amount; }
    public String getUnit() { return unit; }
    
    // Value equality
    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof CarbonFootprint)) return false;
        CarbonFootprint that = (CarbonFootprint) o;
        return Double.compare(that.amount, amount) == 0 && unit.equals(that.unit);
    }
    
    @Override
    public int hashCode() {
        return Objects.hash(amount, unit);
    }
}
```

### Repository Pattern

```java
public interface ActivityRepository {
    Optional<Activity> findById(String tenantId, String activityId);
    List<Activity> findByTenantId(String tenantId);
    void save(Activity activity);
    void delete(String tenantId, String activityId);
}

public class DynamoDBActivityRepository implements ActivityRepository {
    
    private final DynamoDBMapper mapper;
    
    public DynamoDBActivityRepository() {
        AmazonDynamoDB client = AmazonDynamoDBClientBuilder.standard().build();
        this.mapper = new DynamoDBMapper(client);
    }
    
    @Override
    public Optional<Activity> findById(String tenantId, String activityId) {
        Activity activity = mapper.load(Activity.class, tenantId, activityId);
        return Optional.ofNullable(activity);
    }
    
    @Override
    public void save(Activity activity) {
        mapper.save(activity);
    }
}
```

## AWS SDK Best Practices

### DynamoDB Mapper

```java
// Use DynamoDBMapper for simple CRUD
DynamoDBMapper mapper = new DynamoDBMapper(dynamoDbClient);
Activity activity = mapper.load(Activity.class, tenantId, activityId);
mapper.save(activity);

// Use conditional expressions for optimistic locking
DynamoDBSaveExpression saveExpression = new DynamoDBSaveExpression()
    .withExpectedEntry("versionId", new ExpectedAttributeValue()
        .withValue(new AttributeValue().withN(String.valueOf(currentVersion)))
        .withComparisonOperator(ComparisonOperator.EQ));
mapper.save(activity, saveExpression);
```

### Query vs Scan

```java
// Good: Use Query with hash key
DynamoDBQueryExpression<Activity> queryExpression = new DynamoDBQueryExpression<Activity>()
    .withHashKeyValues(new Activity(tenantId))
    .withConsistentRead(false);
List<Activity> activities = mapper.query(Activity.class, queryExpression);

// Avoid: Full table scan (expensive)
DynamoDBScanExpression scanExpression = new DynamoDBScanExpression();
List<Activity> allActivities = mapper.scan(Activity.class, scanExpression);
```

## Error Handling

### Custom Exception Hierarchy

```java
public class NuoaException extends RuntimeException {
    private final int statusCode;
    
    public NuoaException(int statusCode, String message) {
        super(message);
        this.statusCode = statusCode;
    }
    
    public int getStatusCode() { return statusCode; }
}

public class NotFoundException extends NuoaException {
    public NotFoundException(String message) {
        super(404, message);
    }
}

public class ValidationException extends NuoaException {
    public ValidationException(String message) {
        super(400, message);
    }
}

public class ConflictException extends NuoaException {
    public ConflictException(String message) {
        super(409, message);
    }
}
```

## JSON Serialization

### Jackson Configuration

```java
private static final ObjectMapper OBJECT_MAPPER = new ObjectMapper()
    .registerModule(new JavaTimeModule())
    .disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS)
    .setSerializationInclusion(JsonInclude.Include.NON_NULL);

// Serialize
String json = OBJECT_MAPPER.writeValueAsString(activity);

// Deserialize
Activity activity = OBJECT_MAPPER.readValue(json, Activity.class);

// Handle errors
try {
    return OBJECT_MAPPER.writeValueAsString(object);
} catch (JsonProcessingException e) {
    throw new InternalServerException("Failed to serialize response", e);
}
```

## Performance Optimization

### Lambda Cold Start Reduction

```java
public class ActivityGetHandler implements RequestHandler<APIGatewayProxyRequestEvent, APIGatewayProxyResponseEvent> {
    
    // Initialize heavy objects outside handler method (reused across invocations)
    private static final AmazonDynamoDB DYNAMO_CLIENT = AmazonDynamoDBClientBuilder.standard().build();
    private static final DynamoDBMapper MAPPER = new DynamoDBMapper(DYNAMO_CLIENT);
    private static final ObjectMapper OBJECT_MAPPER = new ObjectMapper();
    
    @Override
    public APIGatewayProxyResponseEvent handleRequest(APIGatewayProxyRequestEvent input, Context context) {
        // Handler logic uses static resources
    }
}
```

### Connection Reuse

```java
// Use PoolingHttpClientConnectionManager for HTTP clients
PoolingHttpClientConnectionManager connectionManager = new PoolingHttpClientConnectionManager();
connectionManager.setMaxTotal(50);
connectionManager.setDefaultMaxPerRoute(10);

CloseableHttpClient httpClient = HttpClients.custom()
    .setConnectionManager(connectionManager)
    .build();
```

## Testing Patterns

See [nuoa-testing-java](../nuoa-testing-java/SKILL.md) for comprehensive testing strategies.

## Code Style

### Naming Conventions

- **Classes**: PascalCase (e.g., `ActivityGetHandler`, `DynamoDBActivityRepository`)
- **Methods**: camelCase (e.g., `findById`, `handleRequest`)
- **Constants**: UPPER_SNAKE_CASE (e.g., `MAX_RETRY_ATTEMPTS`, `DEFAULT_PAGE_SIZE`)
- **Variables**: camelCase (e.g., `activityId`, `tenantId`)

### SOLID Principles

- **Single Responsibility**: Each class has one reason to change
- **Open/Closed**: Open for extension, closed for modification
- **Liskov Substitution**: Subtypes must be substitutable for base types
- **Interface Segregation**: Many specific interfaces better than one general
- **Dependency Inversion**: Depend on abstractions, not concretions

## Common Patterns

### Builder Pattern

```java
public class Activity {
    private String tenantId;
    private String activityId;
    private String name;
    
    private Activity(Builder builder) {
        this.tenantId = builder.tenantId;
        this.activityId = builder.activityId;
        this.name = builder.name;
    }
    
    public static class Builder {
        private String tenantId;
        private String activityId;
        private String name;
        
        public Builder tenantId(String tenantId) {
            this.tenantId = tenantId;
            return this;
        }
        
        public Builder activityId(String activityId) {
            this.activityId = activityId;
            return this;
        }
        
        public Builder name(String name) {
            this.name = name;
            return this;
        }
        
        public Activity build() {
            return new Activity(this);
        }
    }
}

// Usage
Activity activity = new Activity.Builder()
    .tenantId("tenant-123")
    .activityId("activity-456")
    .name("Office Electricity")
    .build();
```

## Logging

```java
// Use Lambda Context logger
context.getLogger().log("Processing activity: " + activityId);

// Structure logs for CloudWatch Insights
String logMessage = String.format("action=get_activity tenant_id=%s activity_id=%s", 
    tenantId, activityId);
context.getLogger().log(logMessage);

// Don't log sensitive data
context.getLogger().log("User email: " + email); // BAD
context.getLogger().log("User ID: " + userId);   // GOOD
```

## Dependencies

### Core Dependencies

```xml
<!-- AWS Lambda -->
<dependency>
    <groupId>com.amazonaws</groupId>
    <artifactId>aws-lambda-java-core</artifactId>
    <version>1.2.2</version>
</dependency>

<!-- AWS Lambda Events -->
<dependency>
    <groupId>com.amazonaws</groupId>
    <artifactId>aws-lambda-java-events</artifactId>
    <version>3.11.0</version>
</dependency>

<!-- AWS SDK DynamoDB -->
<dependency>
    <groupId>com.amazonaws</groupId>
    <artifactId>aws-java-sdk-dynamodb</artifactId>
    <version>1.12.400</version>
</dependency>

<!-- Jackson -->
<dependency>
    <groupId>com.fasterxml.jackson.core</groupId>
    <artifactId>jackson-databind</artifactId>
    <version>2.14.2</version>
</dependency>

<dependency>
    <groupId>com.fasterxml.jackson.datatype</groupId>
    <artifactId>jackson-datatype-jsr310</artifactId>
    <version>2.14.2</version>
</dependency>
```

## Related Skills

- [nuoa-testing-java](../nuoa-testing-java/SKILL.md): Java testing strategies
- [domain-driven-design](../domain-driven-design/SKILL.md): DDD patterns
- [aws-solution-architect](../aws-solution-architect/SKILL.md): AWS best practices
- [nuoa-update-lambda](../nuoa-update-lambda/SKILL.md): Lambda deployment
