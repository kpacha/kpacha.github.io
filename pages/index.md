---
title: Blogging
subtitle: for fun and profit
---

{{ render_document(carew.posts|last) }}

{% if carew.posts|slice(0, -1) %}
	## Older blog posts

	{{ render_documents(paginate(carew.posts|reverse|slice(1))) }}
{% endif %}