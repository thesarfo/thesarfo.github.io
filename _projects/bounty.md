---
layout: page
title: "Bounty"
excerpt: "A library that generates realistic test data for Java applications"
github_link: https://github.com/thesarfo/bounty
---

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Core Components](#core-components)
- [Basic Usage](#basic-usage)
- [Field Types](#field-types)
- [Constraints](#constraints)
- [Relationships](#relationships)
- [Data Export](#data-export)
- [Integration Examples](#integration-examples)
    - [Spring Boot Database Seeding](#spring-boot-database-seeding)
    - [Generate SQL Scripts](#generate-sql-scripts)
    - [Quarkus - Panache](#quarkus)
    - [Micronaut](#micronaut)
- [Advanced Usage](#advanced-usage)


## Overview

Bounty helps you create realistic test data for your Java applications. Instead of manually crafting test data or using random values, Bounty lets you define data models and generates values that look like real-world data. With this library, you can:


- Define entities with various field types (names, emails, dates, etc.)
- Apply constraints to ensure data validity
- Create relationships between entities
- Export data to JSON, SQL, or CSV
- Integrate with frameworks like Spring Boot, Micronaut, Quarkus etc.
- Streamline unit and integration testing.

## Quick Start

If all you're looking for is a way to generate sample data, this is all you need to do.

Add the dependency to your project

```xml

<dependency>
    <groupId>io.github.thesarfo</groupId>
    <artifactId>bounty</artifactId>
    <version>1.0.1</version>
</dependency>
```

This is all you need
```java
// Create a generator
TestDataGenerator generator = new TestDataGenerator();

// Define an entity
EntityDefinition person = generator.defineEntity("Person")
    .withField("firstName", FieldType.FIRST_NAME)
    .withField("lastName", FieldType.LAST_NAME)
    .withField("email", FieldType.EMAIL)
    .withField("age", FieldType.INTEGER, c -> 
        ((NumericConstraint)c).min(18).max(80));

// Generate 100 people
DataSet dataSet = generator.generate()
    .entities(person, 100)
    .build();

// Export to JSON
dataSet.exportToJson(new File("people.json"));
```

## Core Components

Bounty consists of several key components that work together:

- **TestDataGenerator**: The main entry point for creating entities and generating data
- **EntityDefinition**: Represents a data model with fields and relationships
- **FieldType**: Defines the types of data that can be generated (names, emails, etc.)
- **Constraint**: Controls how values are generated with validation rules
- **DataSet**: The output containing generated entities that can be exported

## Basic Usage

### Creating a Generator

Start by creating a TestDataGenerator instance:

```java
TestDataGenerator generator = new TestDataGenerator();
```

### Defining Entities

Define your data model:

```java
EntityDefinition user = generator.defineEntity("User")
    .withField("id", FieldType.UUID)
    .withField("username", FieldType.USERNAME)
    .withField("email", FieldType.EMAIL)
    .withField("registeredAt", FieldType.TIMESTAMP);
```

### Generating Data

Generate a specific number of entities:

```java
DataSet dataSet = generator.generate()
    .entities(user, 50)
    .build();
```

### Accessing Generated Data

Retrieve and use the generated data:

```java
List<Map<String, Object>> users = dataSet.getEntities("User");
for (Map<String, Object> user : users) {
    String username = (String) user.get("username");
    String email = (String) user.get("email");
    // Use the data...
}
```

## Field Types

Bounty supports a variety of field types through the `FieldType` enum:

### Basic Types
- `UUID`: Unique identifiers
- `BOOLEAN`: True/false values
- `INTEGER`: Whole numbers
- `DECIMAL`: Floating-point numbers
- `STRING`: Short text
- `TEXT`: Longer text
- `ENUM`: Enumerated values

### Identity Types
- `FIRST_NAME`: First names
- `LAST_NAME`: Last names
- `FULL_NAME`: Complete names
- `EMAIL`: Email addresses
- `USERNAME`: User identifiers
- `PASSWORD`: Password strings

### Date and Time
- `DATE`: Calendar dates
- `TIME`: Time values
- `TIMESTAMP`: Date and time

### Address Types
- `STREET_ADDRESS`: Street addresses
- `CITY`: City names
- `STATE`: States/provinces
- `COUNTRY`: Country names
- `ZIP_CODE`: Postal codes

### Content Types
- `PARAGRAPH`: Multi-sentence text
- `SENTENCE`: Single sentences

## Constraints

Control how values are generated using constraints:

### Common Constraints

Available on all field types:

```java
.withField("status", FieldType.STRING, constraint -> constraint
    .nullable()           // Allow null values
    .unique()             // Ensure uniqueness
    .defaultValue("NEW")  // Set default
    .values("NEW", "ACTIVE", "SUSPENDED") // Limit to specific values
)
```

### Numeric Constraints

For INTEGER and DECIMAL fields:

```java
.withField("age", FieldType.INTEGER, constraint -> {
    NumericConstraint nc = (NumericConstraint) constraint;
    nc.min(18)       // Minimum value
      .max(65)       // Maximum value
      .positive();   // Ensure positive values
})
```

### String Constraints

For text-based fields:

```java
.withField("bio", FieldType.TEXT, constraint -> {
    StringConstraint sc = (StringConstraint) constraint;
    sc.minLength(100)    // Minimum length
      .maxLength(500);   // Maximum length
})
```

### Date Constraints

For date/time fields:

```java
.withField("birthDate", FieldType.DATE, constraint -> {
    DateConstraint dc = (DateConstraint) constraint;
    dc.past()            // Date in the past
      .yearsAgo(100)     // Maximum years in the past
      .after("1950-01-01"); // Minimum date
})
```

## Relationships

Bounty supports different types of entity relationships:

### One-to-One

```java
EntityDefinition user = generator.defineEntity("User")
    .withField("id", FieldType.UUID)
    .withField("username", FieldType.USERNAME);

EntityDefinition profile = generator.defineEntity("Profile")
    .withField("id", FieldType.UUID)
    .withField("bio", FieldType.TEXT);

// Each user has one profile
user.withRelationship("profile", profile, RelationType.ONE_TO_ONE);
```

### One-to-Many

```java
EntityDefinition author = generator.defineEntity("Author")
    .withField("id", FieldType.UUID)
    .withField("name", FieldType.FULL_NAME);

EntityDefinition book = generator.defineEntity("Book")
    .withField("id", FieldType.UUID)
    .withField("title", FieldType.STRING);

// Each author has many books
author.withRelationship("books", book, RelationType.ONE_TO_MANY);
```

### Many-to-Many

```java
EntityDefinition student = generator.defineEntity("Student")
    .withField("id", FieldType.UUID)
    .withField("name", FieldType.FULL_NAME);

EntityDefinition course = generator.defineEntity("Course")
    .withField("id", FieldType.UUID)
    .withField("name", FieldType.STRING);

// Students take multiple courses, courses have multiple students
student.withRelationship("courses", course, RelationType.MANY_TO_MANY);
```

## Data Export

Bounty allows exporting data in different formats:

### JSON

```java
dataSet.exportToJson(new File("data.json"));
```

### SQL

```java
dataSet.exportToSql(new File("seed.sql"));
```

### CSV

```java
dataSet.exportToCsv(new File("data.csv"));
```

## Integration Examples

### Spring Boot Database Seeding

```java
@Bean
public CommandLineRunner seedDatabase() {
    return args -> {
        if (isDevelopmentMode()) {
            TestDataGenerator generator = new TestDataGenerator();
            
            // Define entities
            EntityDefinition customer = generator.defineEntity("Customer")
                .withField("id", FieldType.UUID)
                .withField("name", FieldType.FULL_NAME)
                .withField("email", FieldType.EMAIL)
                .withField("createdAt", FieldType.TIMESTAMP, constraint -> {
                    DateConstraint dc = (DateConstraint) constraint;
                    dc.past().daysAgo(365);
                });
                
            // Generate data
            DataSet dataSet = generator.generate()
                .entities(customer, 50)
                .build();
                
            // Convert to domain objects and save
            List<Customer> customerEntities = dataSet.getEntities("Customer").stream()
                    .map(data -> {
                        Customer c = new Customer();
                        c.setId(UUID.fromString((String)data.get("id")));
                        c.setName((String)data.get("name"));
                        c.setEmail((String)data.get("email"));
                        c.setPhone((String)data.get("phone"));
                        c.setCreatedAt((Date)data.get("createdAt"));
                        return c;
                    })
                    .collect(toList());
                
                customerRepository.saveAll(customerEntities);
    };
}
```

### Generate SQL Scripts
```java
    public void generateSqlScripts() {
        TestDataGenerator generator = new TestDataGenerator();
        
        // Define entities
        EntityDefinition customer = generator.defineEntity("customers")  
            .withField("id", FieldType.UUID)
            .withField("name", FieldType.FULL_NAME)
            .withField("email", FieldType.EMAIL, c -> c.unique())
            .withField("created_at", FieldType.TIMESTAMP);  
            
        EntityDefinition product = generator.defineEntity("products")
            .withField("id", FieldType.UUID)
            .withField("name", FieldType.STRING)
            .withField("price", FieldType.DECIMAL, c -> 
                ((NumericConstraint)c).min(5.99).max(199.99))
            .withField("stock", FieldType.INTEGER, c -> 
                ((NumericConstraint)c).min(0).max(1000));
                
        // Generate data
        DataSet dataSet = generator.generate()
            .entities(customer, 100)
            .entities(product, 50)
            .build();
            
        // Export as SQL (will create INSERT statements)
        File sqlFile = new File("src/main/resources/data.sql");
        dataSet.exportToSql(sqlFile);
    }
```

### Quarkus

```java
@Transactional
void generateData(@Observes StartupEvent event) {
    if (Profile.getActiveProfile().equals("dev")) {
        TestDataGenerator generator = new TestDataGenerator();

        EntityDefinition product = generator.defineEntity("Product")
            .withField("id", FieldType.UUID)
            .withField("name", FieldType.STRING)
            .withField("description", FieldType.TEXT)
            .withField("price", FieldType.DECIMAL, c ->
                ((NumericConstraint) c).min(9.99).max(299.99))
            .withField("createdAt", FieldType.TIMESTAMP);

        DataSet dataSet = generator.generate()
            .entities(product, 50)
            .build();

        // Convert to Panache entities and persist
        List<Product> products = dataSet.getEntities("Product").stream()
            .map(data -> {
                Product p = new Product();
                p.id = UUID.fromString((String) data.get("id"));
                p.name = (String) data.get("name");
                p.description = (String) data.get("description");
                p.price = (BigDecimal) data.get("price");
                p.createdAt = (Date) data.get("createdAt");
                return p;
            })
            .collect(Collectors.toList());

        products.forEach(p -> em.persist(p));
    }
}
```

### Micronaut
```java
@EventListener
@Transactional
public void onStartup(StartupEvent event) {
    if (Environment.isActive("dev") && productRepository.count() == 0) {
        TestDataGenerator generator = new TestDataGenerator();

        // Define entities
        EntityDefinition category = generator.defineEntity("Category")
            .withField("id", FieldType.UUID)
            .withField("name", FieldType.STRING, c -> c.unique())
            .withField("description", FieldType.TEXT);

        EntityDefinition product = generator.defineEntity("Product")
            .withField("id", FieldType.UUID)
            .withField("name", FieldType.STRING)
            .withField("price", FieldType.DECIMAL, c ->
                ((NumericConstraint) c).min(1.0).max(1000.0))
            .withField("available", FieldType.BOOLEAN);

        // Setup relationships
        category.withRelationship("products", product, RelationType.ONE_TO_MANY);

        // Generate data
        DataSet dataSet = generator.generate()
            .entities(category, 5)
            .entities(product, 50)
            .build();

        // Save categories
        List<Category> categories = dataSet.getEntities("Category").stream()
            .map(data -> {
                Category c = new Category();
                c.setId(UUID.fromString((String) data.get("id")));
                c.setName((String) data.get("name"));
                c.setDescription((String) data.get("description"));
                return c;
            })
            .collect(Collectors.toList());

        categoryRepository.saveAll(categories);

        // Save products with category relationships
        List<Product> products = new ArrayList<>();
        for (Map<String, Object> productData : dataSet.getEntities("Product")) {
            Product p = new Product();
            p.setId(UUID.fromString((String) productData.get("id")));
            p.setName((String) productData.get("name"));
            p.setPrice((BigDecimal) productData.get("price"));
            p.setAvailable((Boolean) productData.get("available"));

            // Get category from relationship
            UUID categoryId = UUID.fromString((String) productData.get("categoryId"));
            Category category = categories.stream()
                .filter(c -> c.getId().equals(categoryId))
                .findFirst()
                .orElseThrow();

            p.setCategory(category);
            products.add(p);
        }

        productRepository.saveAll(products);
    }
}
```

## Advanced Usage

### Custom Generators

For specialized fields, you can create your own custom generators. All you need to do is to implement the `Generator` interface, and register your custom Generator

```java
public class CreditCardGenerator implements Generator {
    private static final String[] CARD_TYPES = {
        "VISA", "MASTERCARD", "AMEX", "DISCOVER"
    };
    
    @Override
    public Object generate(Constraint constraint) {
        if (constraint.getDefaultValue() != null) {
            return constraint.getDefaultValue();
        }
        
        String type = CARD_TYPES[(int)(Math.random() * CARD_TYPES.length)];
        String number;
        
        switch (type) {
            case "VISA":
                number = "4" + generateDigits(15);
                break;
            case "MASTERCARD":
                number = "5" + generateDigits(15);
                break;
            // Other card types...
            default:
                number = generateDigits(16);
        }
        
        return number;
    }
    
    private String generateDigits(int length) {
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < length; i++) {
            sb.append((int)(Math.random() * 10));
        }
        return sb.toString();
    }
}

// Register the custom generator
GeneratorFactory.registerGenerator(FieldType.CREDIT_CARD, new CreditCardGenerator());

// Use it in your entity definitions
.withField("paymentMethod", FieldType.CREDIT_CARD)
```

### Performance Optimization

If you work with large datasets, you can generate data in batches. Below is an example:

```java
// Batch generation
TestDataGenerator generator = new TestDataGenerator();
EntityDefinition user = generator.defineEntity("User")
    .withField("id", FieldType.UUID)
    .withField("email", FieldType.EMAIL);

// Generate in batches of 1000
int totalUsers = 100000;
int batchSize = 1000;
int batches = totalUsers / batchSize;

for (int i = 0; i < batches; i++) {
    DataSet batch = generator.generate()
        .entities(user, batchSize)
        .build();
        
    // Process batch (e.g., insert into database)
    processBatch(batch.getEntities("User"));
    
    // Clear memory
    System.gc();
}
```