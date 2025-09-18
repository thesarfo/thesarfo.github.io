---
layout: post
title: "Stitching Rain Windows"
categories:
  - lesson
comments: true
--- 

A few days back, I had to work on a feature that predicts when it’s going to rain. The data I had to work with wasn’t magical at all..it was just hourly forecasts for the day. 


The task was simple in theory: group rainy hours together into something meaningful. Basically, turn scattered hourly data into neat “rain windows” that made sense to a human.

At first I was doing it in a clumsy way.. checking if the hour had rain, pushing some values into lists, closing things off when the rain stopped, and starting again if the rain came back. It was working but felt hacky, like I was combining conditions together. But I felt like I had seen this before, so I did a little snooping and realized I saw a similar pattern in a LeetCode problem.

The [Video Stitching](https://leetcode.com/problems/video-stitching/description/) problem asks you to stitch overlapping "video clips" into one continuous timeline. That’s exactly what I was doing, each rainy hour was a clip. If the next hour was also rainy, extend the clip. If not, close it off. That shift in perspective cleaned everything up. Instead of special-casing everything, I treated rain like intervals. Start a window, extend it, close it. Done.

The code turned out pretty clean after that. I tracked a current window while checking the forecast. If an hour qualified as “rain”, I extended the window. If it didn’t, I finalized the window, averaged the probabilities, figured out the dominant intensity, and saved it. At the very end, I closed any still-open window. There was even a fun little edge case: if a window only had a single rainy hour, I added a one-hour buffer so the start and end times weren’t identical.

What I liked most was how natural this felt once I recognized the pattern. On the surface, weather data and video clips have nothing in common. But under the hood, they’re both just interval problems. And once I thought of it that way, the solution almost wrote itself.

I don’t necessarily want to make this come off as a “see, LeetCode is useful in real life!” vibe. I didn’t reuse code from LeetCode, I reused the way of thinking. Having seen this problem before meant I didn’t overengineer. I just mapped it to a shape I already knew.

The lesson for me is simple, so much of programming is just spotting patterns. Whether it’s intervals, sliding windows, graphs, or whatever... problems repeat themselves, just in different ways. The sooner you spot the pattern, the sooner you can stop overthinking and just solve it.

Engineering is often about seeing through the mess and recognizing the shape of the problem underneath. Once you see it, the rest is just code.
