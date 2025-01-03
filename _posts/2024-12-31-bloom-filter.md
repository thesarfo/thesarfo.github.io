---
layout: post
title: "What Happens When You Try to Pick a Username?"
categories:
  - system-design
comments: true
tags:
    - bloom filter
description:
    There's some smart tech going on behind the scenes
--- 

I've been implementing authentication for a pet project I'm working on, and I had a bunch of reserved usernames I didn't want my users to get access to. It wouldn't make sense for someone to have a username like "admin" or "superuser" — you get the idea. So, I started looking into how to go about this. That’s when I remembered something: Have you ever tried creating a new account and immediately gotten hit with the "Username is already taken" message? You try adding your birth year, a random number, or even something quirky, but it seems like every combination is snatched up already.

This got me thinking — how do giant sites like Facebook, Instagram, or Gmail check username availability so quickly, even with millions or billions of users? What I found was pretty cool (kind of).


### The Old School Way: Linear Search? (Not So Great)
Imagine Instagram is storing all of its usernames in a huge list. Every time you enter a new username, the software checks the entire list to see if your choice is already taken.

Now, this doesn’t sound too efficient, does it? For a site like Instagram with billions of users, the software would have to go through each name one by one. That’s a lot of data to sift through, which would take way too long. Honestly, this used to be my approach too, a simple O(n) database query never hurt anybody - but I digress :)

### What About Binary Search? That's Better
Instead of checking every username one by one, a binary search can help speed things up. Here’s how:

* Instagram keeps its data organized in alphabetical order, kind of like a giant dictionary of usernames.
* When you enter a username, it checks the one in the middle of the list.
* If it’s a match, your username is rejected.
* If not, it checks if your username comes before or after the middle one, cutting the list in half each time.

By dividing the list in half with each check, the software eliminates 750 million usernames in one step! In just 30 steps (which is less than a minute), it’ll either find your username or reject it. Much faster than the linear search, right?

But then, I found something cooler - [Bloom Filter](https://brilliant.org/wiki/bloom-filter/#:~:text=A%20bloom%20filter%20is%20a,is%20added%20to%20the%20set.)

### The Super Smart Way
Now, some websites go a step further. They use something called a **Bloom filter**, which helps them figure out if a username might be taken without checking the entire list at all.

Here’s how a Bloom filter works:

1. **Hashing**: When you enter a username, the Bloom filter hashes it. Hashing is like turning your username into a shorter identifier — sort of like a car's number plate for data. This identifier is usually fixed in length, regardless of how long the original data (your username) was.

2. **Buckets**: Now, the Bloom filter stores this hashed identifier in a "bucket," which is bsically just a section of memory. There are multiple buckets, and each bucket corresponds to a hash value.

3. **Checking**: When you try to enter a username, the Bloom filter checks the corresponding buckets for that hashed identifier. If the bucket is empty, then the username is definitely available. If it's full, then the username might already exist.

4. **False Positives**: Here’s where things get tricky. If the filter says "yes," the username might be taken, but it’s not a guarantee. It’s possible for the filter to say a name is taken when it actually isn’t. This is called a [false positive](https://en.wikipedia.org/wiki/False_positives_and_false_negatives)

The cool thing is, Bloom filters work super fast because they don’t have to search the entire list. They just quickly check if the data is there or not, using the hash values

This is where the **space-time tradeoff** comes into play. Bloom filters are fast because they don’t need to go through the entire list — they just check a few bits. But, the risk is that you might get a false positive. But you can work around the likelihood of false positives by changing the size of the filter. The more space you give the Bloom filter, the lower the chances of getting a false positive

Let's understand with an example:

Suppose we have a bucket size of 10 and 3 hash functions which give us 3 unique identifiers.

And now, I want to use the username "ElonMusk". "ElonMusk", when passed through these hash functions, gives us the values 2, 5, 7. The filter quickly fills the bucket with these identifiers. Like so

![Bucket filled with 2, 5, 7](../assets/blog-imgs/bloom-filter/bf-1.svg)

Now, assuming I enter "BillGates" into the bucket. We will also get unique identifiers for this name. Let's say 3, 6, 9 - which is then filled into the bucket. Our bucket now looks like this.

![Bucket filled with 3, 6, 9](../assets/blog-imgs/bloom-filter/bf-2.svg)

Here's how the magic works. Anytime somebody else wants to use the name "ElonMusk", the filter checks the bucket to see if the values 2, 5 and 7 are empty, in this case they are not - so it means that username is taken.

Similarly, if someone wants the username "Zuck", the function may give us 1, 4, 8 as identifiers and the filter will check if they are empty - which they are, so "Zuck" is available. 


But but but, here's the thing, if someone wants to use the name "Messi" and we get 2, 6, and 8 as identifiers, as usual the bucket checks to see if those spots are empty. Now, the spots for 2, 6 and 8 have been taken by previous usernames which are not "Messi" - but since those spots are already taken, the buckets simply thinks the username "Messi" is taken when it is actually available. This is the **false positive** I spoke of earlier.

### Which One’s Better?
Each one has its pros and cons. A binary search works well when the data is sorted, like Facebook’s username list. Bloom filters, on the other hand, are great for quickly checking if something might exist, though they can sometimes give false positives.

I heard companies like Reddit prefer binary search for its efficiency, while Medium uses Bloom filters to suggest articles based on what you’ve read before. It all depends on what’s most important: speed or precision.

But with computers getting smarter everyday, even the simple db query seems feasible. But it's nice to know how many different approaches there are to solving what might be a simple problem.