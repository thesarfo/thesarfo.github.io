---
layout: post
title: "Serverless Architecture: What I've Learned the Hard Way"
categories:
  - aws
tags:
  - aws
image: /assets/headers/serverless.png
comments: true
--- 

After spending some time building serverless applications, I've learned that the fancy marketing only tells half the story. Yes, serverless is amazing - I'm still a huge fan - but there are plenty of "intricacies" that have caught me (and teams I've been on) off guard. I just want to share what I've discovered about serverless architecture(from an advanced perspective), both the challenges and the new possibilities.

## The Serverless Specifications They Probably Don't Tell You About

### At-Least-Once Delivery

The first time I encountered this issue, I was building what I thought was a simple "cron job" replacement using Lambda. Everything worked beautifully in testing, but when deployed, I occasionally saw the same job running twice. That's when I discovered Lambda's "at-least-once delivery" guarantee.

Here's the thing: Lambda guarantees your function will be called when triggered, but it doesn't guarantee it will be called **exactly once**. Most of the time (>99%), your function runs once per event. But occasionally, it might run multiple times. For many tasks, this doesn't matter - but when it does, it _really_ does.

I remember a moment when our analytics dashboard started showing duplicate entries for certain user actions. At first, I thought it was a frontend bug, but after some digging, we realized our Lambda function was processing the same event multiple times, inflating our metrics. Fun times.

After some frantic debugging, I found three ways to handle this:

1. **Build idempotent systems**: This is my preferred solution now. I design my functions so they can run multiple times safely with the same outcome. For example, when writing to DynamoDB, I use UpdateItem operations that are naturally idempotent. For S3, uploading the same file multiple times is fine.

2. **Accept occasional duplicates**: For some use cases, like generating reports or sending internal notifications, I've decided that occasional duplicates are acceptable. The engineering cost to prevent them wasn't worth it.

3. **Track processed events**: For critical operations where duplicates are never acceptable, I track AWS request IDs in DynamoDB with conditional writes. It adds complexity, but it works.

```javascript
// Simplified example of checking for duplicate processing
async function handler(event, context) {
  const requestId = context.awsRequestId;
  
  try {
    // Try to write the request ID to DynamoDB with a condition that it doesn't exist
    await dynamoDB.putItem({
      TableName: 'ProcessedEvents',
      Item: { requestId: requestId },
      ConditionExpression: 'attribute_not_exists(requestId)'
    }).promise();
    
    // If we get here, this is the first time processing this event
    // Proceed with the actual work...
    
  } catch (error) {
    if (error.code === 'ConditionalCheckFailedException') {
      console.log('Already processed this event, skipping');
      return;
    }
    throw error;
  }
}
```

### When Lambda Scales Too Well

Lambda's auto-scaling is both a blessing and a curse. I learned this lesson when our background processing system suddenly got started receiving about 4x the normal traffic. Lambda handled it beautifully, spinning up lots of concurrent functions. Our database... not so much.

Our RDS instance was swamped with connections, eventually causing our entire application to crash(well, just that small part). Lambda scaled perfectly, but our database couldn't keep up.

Since then, I've used these approaches:

1. **Use serverless-friendly databases**: Whenever possible, I use DynamoDB or Aurora Serverless, which can handle Lambda's scaling behavior much better.

2. **Control the scaling upstream**: For APIs, I usually set throttling limits in API Gateway. For SQS-triggered functions, I carefully set batch sizes.

3. **Use reserved concurrency**: This has been a lifesaver. By setting a Lambda function's reserved concurrency to, say, 10, I ensure it will never scale beyond 10 concurrent invocations, protecting downstream systems.

Here's a snippet from a SAM template I use for functions that connect to traditional databases:

```yaml
DbFunctionHandler:
  Type: AWS::Serverless::Function
  Properties:
    Handler: index.handler
    Runtime: nodejs18.x
    ReservedConcurrentExecutions: 10  # Protect the database!
```

4. **Design hybrid architectures deliberately**: I've learned to place message queues between Lambda and traditional systems. My API Lambda functions publish to SNS, and another Lambda function with reserved concurrency processes these messages at a safe rate for the database. This gives me the best of both worlds.

### Cost Surprises

*Where* you put your code in a Lambda function matters tremendously for cost. I once refactored what I thought was an innocent piece of code, moving an API key decryption from inside the handler to the constructor, and unexpectedly reduced my AWS bill by a very huge margin.

The difference was that, in the first version, I was calling KMS to decrypt on every event. In the second, I only decrypted once per function instance:

```javascript
// EXPENSIVE VERSION - decrypts on every invocation
exports.handler = async (event) => {
  const encryptedApiKey = process.env.ENCRYPTED_API_KEY;
  const apiKey = await decryptWithKms(encryptedApiKey);
  // Use apiKey...
};

// COST-EFFICIENT VERSION - decrypts only on cold starts
let apiKey;
async function initialize() {
  const encryptedApiKey = process.env.ENCRYPTED_API_KEY;
  apiKey = await decryptWithKms(encryptedApiKey);
}

exports.handler = async (event) => {
  if (!apiKey) await initialize();
  // Use apiKey...
};
```

This pattern applies to any external service calls that don't need to be made on every invocation - SDK clients, database connections, configuration loading, etc.

## New Architectural Patterns That Only Make Sense With Serverless

After working through these challenges, I've discovered that serverless enables entirely new ways of building systems that weren't practical before.

### **1.  Component Reuse with the Serverless Application Repository**

I used to spend days building the same boilerplate components for each new project - auth layers, monitoring setups, standard data processing workflows. Now I publish them to the Serverless Application Repository (SAR) once and reuse them everywhere.

My team has built a library of internal SAR applications that standardize:
- Custom authorizers for API Gateway
- Monitoring and alerting stacks
- Common data processing pipelines

I embed these in other applications using nested stacks:

```yaml
MyAuthLayer:
  Type: AWS::Serverless::Application
  Properties:
    Location:
      ApplicationId: arn:aws:serverlessrepo:us-east-1:123456789012:applications/my-auth-layer
      SemanticVersion: 1.0.5
    Parameters:
      UserPoolId: !Ref MyUserPool
```

This has dramatically improved our development velocity and standardization across projects.

### **2. Going Global With Multi-Region Architectures That Actually Work**

Before serverless, deploying to multiple regions was technically possible but practically unfeasible for most teams. The costs and operational complexity were too high. With Lambda's pay-per-use model, I've built globally distributed applications that would have been unthinkable just a couple of years ago.

I recently deployed an API to five regions around the world, using Route53's geolocation routing to direct users to their closest region. The amazing thing? It costs basically the same as running in one region, since we only pay for actual usage. If a region is idle, we pay nothing.

For state management, I use DynamoDB global tables, which automatically replicate data across regions. This gives us both low latency for users worldwide and incredible resilience - if an entire AWS region goes down (yes, it happens!), our application continues to work.

Here's the basic architecture I use:

1. Deploy identical Lambda+API Gateway stacks to multiple regions
2. Use DynamoDB global tables for data that needs global replication
3. Set up Route53 geolocation routing to direct users to their nearest region
4. Add health checks and failover routing for automated disaster recovery

The real game-changer is that with Lambda's pricing model, those backup regions cost nothing until they're needed. Traditional architecture would have us paying for idle EC2 instances in every region!

### **3. Edge Computing**

I've started experimenting with Lambda@Edge, which lets you run functions at AWS edge locations worldwide without thinking about regions at all. While it has limitations today (CloudFront-only trigger, less memory, etc.), I think it represents the future of cloud computing.

I've used Lambda@Edge for:
- Customizing content based on user location
- Performing authentication at the edge
- A/B testing without origin server changes

It's still early days for this technology, but I believe we're moving toward truly "regionless" computing where geographic considerations are completely abstracted away.

## What I Wish I'd Known Earlier

After building quite a number of serverless applications, here's what I wish someone had told me from the start:

1. **Read the docs** - The subtleties of Lambda's execution model, event sources, and integration points matter tremendously. What seems like a small detail in the docs can have major implications in production.

2. **Think differently about architecture** - The best serverless solutions don't just lift-and-shift traditional patterns. They embrace the unique characteristics of managed services.

3. **Invest in monitoring** - Distributed systems are harder to debug. I've saved countless hours by investing in good observability from day one.

4. **Embrace the constraints** - Lambda's limitations (15-minute timeout, etc.) initially feel restrictive, but they've pushed me to build more resilient, loosely-coupled systems.

5. **Cost optimization is an ongoing process** - What's efficient today might not be tomorrow as usage patterns change. I regularly review my implementations for optimization opportunities.


I believe we're just at the beginning of what's possible with serverless architectures. AWS continues to remove limitations and add capabilities that make more complex use cases viable. Service integration is improving - look at RDS Proxy for helping Lambda connect to relational databases. Global resilience is becoming simpler with multi-region capabilities built into more services. Development experiences are improving with better local testing tools. The most exciting developments are in the composition and orchestration layer - Step Functions, EventBridge, and SAR are making it easier to build complex, maintainable applications from smaller components.


Serverless architecture comes with its own set of challenges and gotchas that aren't always obvious from the marketing materials. But once you understand these nuances, it enables entirely new approaches to building resilient, scalable applications.

I've found that the "less server" approach means spending less time on infrastructure and operations, but it requires more thoughtful architecture. The trade-off has been absolutely worth it for me.