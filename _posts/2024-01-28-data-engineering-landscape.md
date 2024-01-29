---
title: Data Engineering Landscape
tags: [data, flume, nix]
categories: devlog
---

For the past few weeks I've been navigating the so-called "data engineering
landscape." Most of my spare time has been spent either reading different books
on data engineering as a whole, or experimenting with different tools often
used in the space.

## Fundamentals of Data Engineering

The primary book I've been working my way through has been
[Fundamentals of Data Engineering](/snapshots/data-engineering-landscape/fundamentals-data-engineering.html).
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

* [Airflow](/snapshots/data-engineering-landscape/airflow.html)
* [Flink](/snapshots/data-engineering-landscape/flink.html)
* [Hadoop](/snapshots/data-engineering-landscape/hadoop.html)
* [Kafka](/snapshots/data-engineering-landscape/kafka.html)
* [NiFi](/snapshots/data-engineering-landscape/nifi.html)
* [Pulsar](/snapshots/data-engineering-landscape/pulsar.html)
* [Spark](/snapshots/data-engineering-landscape/spark.html)

I've had a chance to experiment with [some of these](https://git.jrpotter.com/r/bootstrap/src/branch/main/specs)
but even so I imagine any real evaluation I make would be cursory at best.
Unless I have a specific reason to use any one of these tools, it'll likely
remain that way. Still, having an even superficial understanding of what these
tools do, has helped frame the space as a whole.

## Database Studies

I am simultaneously working through CMU's
[database course](/snapshots/data-engineering-landscape/cmu-course.html) with a
friend. The [latest lecture](https://www.youtube.com/watch?v=q4W5r3GR0OU) I am
watching hit on columnar stores, which was great timing considering it's
relevance to OLAP-based workloads.
