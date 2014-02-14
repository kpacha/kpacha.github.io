---
layout: post
title:  Improving the css/js compression process
tags:
    - php
    - java
    - yui-compressor
    - jetty
---

Everybody in the web business knows that deploying uncompressed css/js files is a bad idea. It is a waste of time and money since storage and bandwith usually are not free resources (this web is a clear exception, so here I do not care too much). And the website will take more time to get fully rendered. So people use tools like [yui-compressor](http://yui.github.io/yuicompressor/) in order to minify their css and javascript files. But adding those compressed files to the SCM tool does not feel right because there is no way to know if the compressed files are up to date with the uncompressed version. The solution is compress those files just before deploying a new version.

This aproach is fine if you are deploying a pre-builded package to your servers. But, what if you are just checking out the code from your SCM? In this scenario, you will need to install your compressing tool (with all its requirements) in every server and trigger the compression process after the checkout. Why would you spend so much time doing the same operation again and again? Are your files different from one host to another or are they almost the same? How often do you deploy? Just take the DRY pattern to the next abstraction level and delegate that process to a dedicated service!

Here [yuicompressor-server](http://kpacha.github.io/yuicompressor-server/) comes up. Since yui-compressor is the most adopted compression tool and since it is a FOSS java project, it sounds good to me to bundle the jar with a lightweight http service and centralize the locally installed compression tool in a dedicated server. This solution gives some extra benefits:

* *Less software requirements on the app servers*. If they are running a pure php-based app, why should they require a jdk?
* *More resource reutilization* since you are instantiating less compressors... And there is a single jvm in a dedicated and customized server!
* *Fault tolerance*. Just launch a set of yuicompressor-server hosts and add them to your deployment process. This HA configuration removes any SPOF (single point of failure) and improves the service continuation because the probability of unsuccesful deployments due errors (related to the compression processes and results) is almost zero.
* *Cachable responses for free*. It is a http service so you can use the cache headers and any network intermediary will cache your responses. Also, you can place a front-end cache (dedicated or embedded) and reduce the response time and server load. [Varnish](https://www.varnish-cache.org/) and [Ehcache](http://ehcache.org/) are your friends... but are you really generating so much requests?

Finally, you will end with a faster deployment process and an easier infraestructure.

For the http service, I choose an embedded [jetty](http://www.eclipse.org/jetty/). I discovered it some time ago playing with the [ninja framework](http://www.ninjaframework.org/) and I love it. It gets a well tested, very stable and pretty fast http server. And it is as easy to use that it requires just few lines of code to get it running!

The yuicompressor-server is not the best solution but it is the next baby-step in the continuous improvement process. It is the small hop you make to get things running better without any big, risky change. Some day in the future, your CI server will handle the css/js compression task before packaging a release and deploy it. Then, after celebrating your new achivement in the long road to the perfect processes and the leanest environment, you will be able to shutdown your compressor server and forget it. Until that happy day, why should you be doing nothing to improve your daily work?

Read more about [yuicompressor-server](http://kpacha.github.io/yuicompressor-server/) or inspect the [code](http://github.com/kpacha/yuicompressor-server/)