---
layout: post
title: "Break Free from Primitive Obsession"
categories:
  - code
---

Every line of code tells a story, and sometimes, that story carries a whiff of trouble — like the unmistakable scent of a code smell. You know the feeling — a sneaky suspicion that your code could use some refinement, but where do you start? Enter the world of primitive obsession, a code smell that might be quietly sabotaging your code quality without you even realizing it.

## What is Primitive Obsession?
Primitive obsession is like that annoying habit we all have of using the wrong tool for the job. Primitive obsession is when you use basic data types (like integers, strings, and doubles) in places where more specialized, meaningful abstractions would be better.

In simpler terms: it’s like storing an entire address as a string instead of creating a dedicated Address class. Sure, it works, but it’s messy and prone to errors. Think of it as putting all your eggs in a basket that’s way too small.

## Why Primitive Obsession is Problematic

### 1. Lack of Context
When primitives are used excessively, the context of the data becomes unclear. A String could be an email, a phone number, or a simple message. This lack of specificity makes the code harder to understand and maintain.

### 2. Scattered Validation Logic
Validation logic for primitives tends to be scattered throughout the codebase. For example, checking if a string is a valid email might be repeated in multiple places, leading to redundancy and potential inconsistencies.

### 3. Poor Type Safety
Using primitives everywhere can lead to type safety issues. For instance, it’s easy to accidentally pass an age where an ID is expected if both are represented as integers (seriously, it happens).

### 4. Difficulty in Refactoring
When primitives are deeply embedded in your code, refactoring becomes challenging. Changing a primitive to a more complex type can require extensive changes across your codebase.

## Identifying Primitive Obsession
Spotting primitive obsession is like finding the needle in the haystack — if the needle was a glaring mistake. Here’s what to look for:

### 1. Data Overload
If you see methods or classes that are overloaded with primitive parameters, you might have a problem. For example:

```java
public class OrderManager {
    public void processOrder(double price, String customerEmail, int orderId) {
        // Process the order
    }
}
```

Or this:

```java
public class User {
    private String email;
    private String phoneNumber;
    private String username;

    // omitted getters and setters
}
```

### 2. Magic numbers and Strings
If you find yourself using numbers and strings directly in your code without clear meaning or explanations:

```java
if (statusCode == 200) {
    // Success
}
```

### 3. Frequent Type Conversions
When you’re constantly converting between primitive types and other objects:

```java
public void processPrice(String priceString) {
    double price = Double.parseDouble(priceString);
    // Use price
}
```

### 4. Repeated Validation Checks for the Same Type of Data
Perhaps the most telling symptom of primitive obsession. When you find yourself repeatedly validating primitives across different parts of your codebase, it often points to the fact that these primitives are being used to represent complex concepts without the benefit of proper abstraction. Take a look at the below code:

```java
public class UserService {

    public void registerUser(String email, String phoneNumber) {
        if (!isValidEmail(email)) {
            throw new IllegalArgumentException("Invalid email");
        }
        if (!isValidPhoneNumber(phoneNumber)) {
            throw new IllegalArgumentException("Invalid phone number");
        }
        // Registration logic
    }

    public void updateUser(String email, String phoneNumber) {
        if (!isValidEmail(email)) {
            throw new IllegalArgumentException("Invalid email");
        }
        if (!isValidPhoneNumber(phoneNumber)) {
            throw new IllegalArgumentException("Invalid phone number");
        }
        // Update logic
    }

    private boolean isValidEmail(String email) {
        // Email validation logic
    }

    private boolean isValidPhoneNumber(String phoneNumber) {
        // Phone number validation logic
    }
}
```

## Addressing Primitive Obsession
Enough talk. Ready to kick primitive obsession to the curb? Here’s how you can clean up your code:

### Step 1: Recognize and Acknowledge
The first step in addressing primitive obsession is recognizing its presence. Look for repeated patterns where primitives are used to represent complex concepts.

### Step 2: Create Value Objects
A value object is a small object that represents a simple entity whose equality is not based on identity but on value. Value objects help encapsulate validation and behavior, making your code more robust and easier to maintain. For example, instead of passing around a double for a Price, create a Price class:

```java
public class Price {
    private final double amount;

    public Price(double amount) {
        if (amount <= 0) throw new IllegalArgumentException("Price must be positive");
        this.amount = amount;
    }

    public double getAmount() {
        return amount;
    }
}
```

Use it like this:

```java
public class OrderManager {
    public void processOrder(Price price) {
        // Process the order
    }
}
```

### Step 3: Encapsulate Primitive Types
For primitive types that represent more complex concepts, encapsulate them in classes. For instance, if you’re using String for a PhoneNumber:

#### Refactoring Example

```java
public class PhoneNumber {
    private final String number;

    public PhoneNumber(String number) {
        if (number == null || number.isEmpty()) throw new IllegalArgumentException("Phone number cannot be null or empty");
        this.number = number;
    }

    public String getNumber() {
        return number;
    }
}
```

Use it like this:

```java
public class Contact {
    private final PhoneNumber phoneNumber;

    public Contact(PhoneNumber phoneNumber) {
        this.phoneNumber = phoneNumber;
    }

    public PhoneNumber getPhoneNumber() {
        return phoneNumber;
    }
}
```

### Step 4: Avoid Magic Numbers
Replace magic numbers with named constants or enums:

#### Refactoring Example

```java
public static final int MAX_RETRIES = 5;
```

Use it like this:

```java
for (int i = 0; i < MAX_RETRIES; i++) {
    // Retry logic
}
```

## Avoiding Primitive Obsession in New Projects

### 1. Design with Value Objects in Mind
When starting a new project, think in terms of value objects from the beginning. Identify the different types of data and their behaviors and create dedicated classes for them.

### 2. Regular Code Reviews
Incorporate regular code reviews focused on identifying and addressing primitive obsession. Encourage your team to think about encapsulation and type safety.

### 3. Educate Your Team
Ensure that your team understands the importance of avoiding primitive obsession. Share articles, conduct workshops, and lead by example in your own code.

## Wrapping It Up
Refactoring away from primitive obsession makes your code cleaner and easier to maintain. By turning primitives into dedicated classes with meaningful names, you not only make your intentions clearer but also centralize validation, preventing data mishaps. This approach boosts type safety, as the compiler helps catch errors from mixing up different types. And when it’s time to tweak how something is represented — like changing email formats — those changes stay contained within the class, sparing the rest of your codebase from any disruption.

I know, primitive obsession might seem like a small issue, but it can lead to big problems in code maintainability and readability. Remember, it’s not just about avoiding a bad smell; it’s about creating a clean, understandable, and maintainable codebase.

So next time you’re tempted to use a primitive type, ask yourself: “Is there a better way to represent this?” You might be surprised at how a bit of refactoring can transform your code from a tangled mess into a work of art. Happy coding!
```

This version retains all the content and structure, now formatted appropriately for Markdown with headers, code blocks, and proper sectioning.