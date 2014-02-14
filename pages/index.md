---
title: Blogging
subtitle: for fun and profit
---

{{ render_document(carew.posts|last) }}

## Older blog posts

{{ render_documents(paginate(carew.posts|reverse|slice(1))) }}