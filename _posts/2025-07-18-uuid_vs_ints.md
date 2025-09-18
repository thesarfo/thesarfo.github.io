---
layout: post
title: "Choice on Primary Keys"
categories:
  - system-design
comments: true
---

Every few months someone says *"Don’t use UUIDs for primary keys"* and suddenly everyone’s arguing again like it’s a brand new debate. I saw one of those takes again recently, and honestly it’s not wrong, but it’s also not that simple.


## So… should you use UUIDs as primary keys?

The short answer is: *it depends.*

Most of the time, I use an auto-incrementing `int` as my primary key, and a UUID for anything that’s exposed to the outside world like API URLs, public identifiers, links, etc.

It gives me the best of both worlds:

* I get fast inserts and small indexes internally
* I don’t have to expose a guessable `id=123` to the public

Is this the "best" way? Maybe. Maybe not. But it’s good enough for 99% of systems we’re building.

## What about distributed systems?

Now this is where things get interesting. Auto-increment IDs work fine… until you start scaling horizontally. In a distributed setup, that auto-increment is tied to a single node or thread. So unless you’re coordinating sequences (which is messy), you’ll run into problems.

UUIDs or better yet, **time-based UUIDs** (like UUIDv7) solve this. You can generate them on any node, any time, without central coordination. You even get some level of ordering depending on the implementation.

Yeah, they're relatively bigger (16 bytes vs 4), but unless you're writing some insanely high-throughput, billion-row-per-week system, **you’ll be fine**. The index bloat and size argument is mostly theoretical for most of us. Especially now that databases are more than capable of handling this stuff.


Integer IDs are easier to work with. You can read them, sort them, debug them easily. But they’re also easy to **predict**.

If someone sees:

```
/orders/1021
```

…they can probably guess there’s an `/orders/1020` and `/orders/1022`. That’s a mild security concern depending on what your app does. You’d need to lock down access controls carefully.

Now if it’s:

```
/orders/4f6d456e-bb49-4317-84cf-bae94307d733
```

Suddenly no one’s guessing anything. I think its just safer to expose something opaque.


## Ordering

Auto-incremented ints are naturally ordered, which can be useful. But again,in a distributed world, that assumption breaks. If you care about order but still want decentralized ID generation, UUIDv7 or Snowflake style IDs give you *roughly chronological* ordering, even across nodes.

Obviously there is clock skew. But do you *really* care if one event appears 10 seconds before another due to a timestamp drift?

If it’s that serious, you probably shouldn’t rely on the PK for sorting anyway.


## So what should you use?

There’s no single right answer. But this is my general rule of thumb:

* Small apps, monoliths, or internal tools? `int` PKs are fine.
* APIs or apps with public exposure? Add a UUID column for external use.
* Distributed or horizontally scaled systems? Consider UUIDv7 or Snowflake IDs.
* If you’re *really* not sure? Use both. `int` for joins and indexing, UUID for external safety.

None of us are building Stripe and Twitter at the same time. Don’t overthink it, but understand the tradeoffs.


At the end of the day, it's not about being dogmatic. It’s about knowing your system, your team, and your scaling needs. Choose what works, and be okay with evolving it later.
