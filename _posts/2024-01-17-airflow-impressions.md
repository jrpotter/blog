---
title: "Airflow: First Impressions"
tags: [airflow, apache, python]
categories: devlog
---

In parallel to working on [Flume](https://git.jrpotter.com/flume), I have been
performing a survey of the data engineering landscape. In the next few updates
I'll touch briefly on some of the tools I've come across and my first
impressions with them. In this post, I'll be talking about my experience with
[Airflow](/snapshots/airflow-impressions/apache-airflow.html) (version 2.7.3).

## Overview

Airflow is a job scheduler. It constructs a dependency graph in the form of a
DAG connecting services dubbed upstream or downstream of one another. Once a
DAG is defined and enabled, a scheduler will periodically search for any DAGs
that should be run and then arrange for its tasks to be executed. It does so at
one minute intervals (by default), continually checking the status of tasks and
their downstream dependencies.

Execution can happen in a number of different environments, but the most common
seem to be [Celery](/snapshots/airflow-impressions/celery.html) and
[Kubernetes](/snapshots/airflow-impressions/kubernetes.html). The
[CeleryExecutor](/snapshots/airflow-impressions/celery-executor.html) uses
pre-defined Celery workers, running operations as Celery tasks. This mode favors
quick boot-time but lacks elasticity and isolation. The
[KubernetesExecutor](/snapshots/airflow-impressions/kubernetes-executor.html)
turns up and down pods as needed for each DAG task. This provides elasticity and
isolation (each DAG-defined task always runs in its own pod), but is slower to
turn-up.

Communication between DAG-defined tasks happen in primarily two ways. First, if
the data to be communicated is small, you can use the baked-in
[XComs](/snapshots/airflow-impressions/xcoms.html) broker. If not, you must use
a custom XComs backend or some 3P storage solution as an intermediary.

## Promises

My experience using Airflow has been limited to just within a [dev environment](https://git.jrpotter.com/blog/example-airflow),
but even a surface level experience can provide insights into the feasibility
of a technology's promises. To continue, we should establish the promises that
Airflow makes.

### Execution Ordering

As a starting point, Airflow promises to make ordering job execution easier.
This is its only real purpose. After all, Airflow is an agnostic tool - it does
not care about what jobs *do*, only that they are done in the right order. On
the surface, I'm not saying anything new. But digging deeper into the subtext,
we see this promise implicitly asserts that executing jobs in the right order is
difficult to do correctly.

This makes me pause. By no means do I think job ordering is easy, but I'm also
not necessarily of the opinion that the onboarding and maintenance burden
introduced by Airflow is the right trade-off. Of course, your mileage may vary,
but my immediate impression is that most projects do not need such a
heavy-handed tool.

In past companies I've worked at, it was almost always sufficient to just use
PostgreSQL's row-level locks for coordination. A service-specific query on
the state of a given row can determine whether or not that row and its data
should be processed. Timeouts, retries, and other functionality are relatively
easy to expand into the schema as needed. In fact, this is essentially how
Airflow itself works:

![Basic Architecture](/assets/img/airflow-impressions/basic-architecture.png)

Of course, this approach has its own fair share of problems (as all approaches
do). For example, if you need to have different execution environments
controlled by a simple configuration change, Airflow makes more sense. If all
you want though is to schedule jobs and have them run after some state is
reached, this "manual" approach is significantly more digestible.

### DAG Representations

Airflow makes another implicit promise - the DAG is the correct way to represent
complicated workflows. This is a perfectly reasonable approach, but its
important your own needs are carefully considered before adoption. Do you need
support for cyclic dependencies between services? Will you ever? Do you need
multiple workers to process the same job?

In many cases, having a strict dependency chain simplifies the way jobs are
organized. In many other cases it's an unnecessary constraint. As a
counter-approach, consider the more manual, row-level lock approach discussed in
the previous section. Cyclic dependencies are already supported (just revert the
row status). Multiple workers can start processing the same job with a
simple schema change.

{% note %}
In many ways, what I'm advocating for here looks more like pubsub then Airflow's
producer-consumer model.
{% endnote %}

Ultimately, it feels restrictive to force everything into a DAG. Considering how
difficult it can be to anticipate business needs, this may force one down a road
where Airflow instructs architectural decisions, instead of Airflow itself
serving a role in the greater architectural picture. If at some point you need
to build or use a service separate from Airflow anyways, it's worth evaluating
the benefits Airflow provides in the interim.

## Conclusion

I am vastly simplifying job orchestration. There are many other considerations
that must be made when building vs. working with some turnkey solution.
Unexpected state (e.g. zombies), scaling, monitoring, deployment, non-job
coordination (e.g. schema changes), etc. Airflow is able to handle some of these
concerns out of the box. That said, I'm of the opinion you'll likely want to
start with a custom-baked solution and only transition to a tool like Airflow if
the situation proves itself unwieldy.
