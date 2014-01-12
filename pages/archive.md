---
title: Archive
subtitle: post stream and other stuffs
navigations: main
layout: doc
---

Posts
----

{{ render_documents(paginate(carew.posts|reverse)) }}

Pages
----

{{ render_documents(paginate(carew.pages)) }}

Or you can {{ link('tags', 'browse all tags') }}.