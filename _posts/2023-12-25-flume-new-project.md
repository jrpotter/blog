---
title: "Flume: New Project"
tags: [c++, data-engineering, elixir, flume]
categories: devlog
image: /assets/img/posters/flume-new-project.png
---

In an effort to write more often, I have decided to maintain a devlog for the
various projects I work on. These posts are likely to be shorter, "stream of
conciousness" journal entries as opposed to my longer blog posts. As of now,
there is no real goal I am associating with these entries outside of them
serving as a potential stepping stone to more consistent writing.

---

To kick the journal off, I will briefly discuss the "Flume" project I have just
begun. The idea stemmed from an early iteration of [BoardWise](https://www.boardwise.gg/)
in which I created a form for chess coaches to fill out. This form had a number
of input fields and the ability to save progress midway. I found forms to be
surprisingly difficult though. Some of the considerations that needed to be made
included:

- Validating finalized form fields
- Saving form fields before finalization (i.e. saving partially completed responses)
- Handling different input types (e.g. text, numbers, files, dates, etc.)
- Serializing data (both on save and on submit)
- Synchronizing the database schema with the expected form data

{% info %}
These problems do not include the issues I felt our (at-the-time) dependency on
[Supabase](https://supabase.com/) introduced. In general, direct
user-to-database communication is not a paradigm I agree with and the need to
think about [RLS](https://www.postgresql.org/docs/current/ddl-rowsecurity.html)
at every step of development was more trouble than it was worth.
{% endinfo %}

Quite a bit can be written on each of the above points, but to distill down to
the point of this post, I feel that there exists a need for a service capable of
ingesting different types of data, running this data through a series of
transformers/validators/etc., and then sending this processed data to another
server. In essence, something akin to a data pipeline but at a *much* smaller
scale. This general thought process was the impetus behind
[Flume](https://git.jrpotter.com/flume).

As of now, very little has been done outside of more thinking around what
exactly a first iteration should be. The rough idea consists of a basic
interface for defining JavaScript/TypeScript functions capable of processing
arbitrary data, running these functions in [V8](https://v8.dev/docs/embed)
isolates, and then sending successfully processed data to a pre-defined webhook.
This likely doesn't sound all that novel, but there exists a lot of nuance
around data processing. I'm hoping there is a particular unexplored facet to
the problem that Flume can explore.

---

The primary user-facing server will be written in Elixir while the "workers"
running the embedded V8 instances will be written in C++.
