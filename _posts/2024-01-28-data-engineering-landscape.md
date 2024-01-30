---
title: Data Engineering Landscape
tags: [data, flume, nix]
categories: devlog
---

For the past few weeks I've been navigating the so-called "data engineering
landscape." Most of my spare time has been spent either reading different books
on data engineering as a whole or experimenting with different tools often
used in the space.

## Fundamentals of Data Engineering

The primary book I've been working my way through has been
[Fundamentals of Data Engineering](https://www.oreilly.com/library/view/fundamentals-of-data/9781098108298/).
This book has been a great introduction to the high-level thinking around
designing data pipelines.

![O'Reilly](/assets/img/data-engineering-landscape/oreilly.jpg)

I haven't finished reading it yet but I plan on finishing it over the next few
weeks.

## Apache Top-Level Projects

The foregoing book intentionally avoids diving into tool-specific concepts. To
help supplement and cement the ideas it introduces, I've also been performing a
separate deep-dive into various top top-level Apache projects often used in
this space. These include:

* [Airflow](https://airflow.apache.org/)
* [Flink](https://flink.apache.org/)
* [Hadoop](https://hadoop.apache.org/)
* [Kafka](https://kafka.apache.org/)
* [NiFi](https://nifi.apache.org/)
* [Pulsar](https://pulsar.apache.org/)
* [Spark](https://spark.apache.org/)

I've had a chance to experiment with [some of these](https://git.jrpotter.com/r/bootstrap/src/branch/main/specs),
but even so I imagine any real evaluation I make would be cursory at best.
Unless I have a specific reason to use any one of these tools, it'll likely
remain that way. Still, having an even superficial understanding of what these
tools do has helped frame the space as a whole.

## Database Studies

I am simultaneously working through CMU's
[database course](https://15445.courses.cs.cmu.edu/fall2022/schedule.html) with
a friend. The [latest lecture](https://www.youtube.com/watch?v=q4W5r3GR0OU) I
am watching hit on columnar stores, which was great timing considering it's
relevance to OLAP-based workloads.
