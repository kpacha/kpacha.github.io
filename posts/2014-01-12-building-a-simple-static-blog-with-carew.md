---
layout: post
title:  Building a simple static blog with carew
tags:
    - php
    - carew
---

I think the better topic for a first post must be 'how did I build this?', so here we go!

First of all, as I want my blog be served at github pages, I create a new repo name kpacha.github.io. The repo has two branches:

* The 'master' branch stores the last static website builded as it's intended to serve the web contents for github pages
* The 'editor' branch stores the carew project and all the markdown pages

So the workflow I'm following here is quite simple:

- checkout the 'editor' branch
- create new post
- commit changes
- re-build website
- merge the new website to master
- commit changes
- push both branches

##Installation

The best way to start with carew is to use the carew boilerplate: You will need composer.

	$ php composer.phar create-project carew/boilerplate my_website -s dev
	$ cd my_website
	$ bin/carew build

That's all, you can browse the web/ directory.

##Posting

Create your post entry

    $ bin/carew generate:post "Your post title"

Edit your entry and rebuild your web

	$ bin/carew build
