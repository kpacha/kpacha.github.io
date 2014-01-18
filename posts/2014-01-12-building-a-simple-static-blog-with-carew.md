---
title:  Building a simple static blog with carew
layout: post
tags:
    - php
    - carew
---

I think the best topic for a first post must be 'how did I build this?', so here we go!

First of all, as I want my blog be served at github pages, I create a new repo name kpacha.github.io. I know the [cookbook](http://carew.github.io/cookbook/hosting.html) recomends an easier way, but I don't want the carew installation on my `master` branch so, my repo has two branches:

* The `master` branch stores the last static website builded as it's intended to serve the web contents for github pages
* The `editor` branch stores the carew project and all the markdown pages

So the workflow I'm following here is quite simple:

- checkout the `editor` branch
- create new post
- re-build website
- commit changes
- merge the new website to `master`
- commit changes
- push both branches


Initial setup
----

Create a new github repo named `<YOUR-GITHUB-USER>.github.io` and clone it somewhere in your system

	$ git clone https://github.com/<YOUR-GITHUB-USER>/<YOUR-GITHUB-USER>.github.io.git
	$ cd <YOUR-GITHUB-USER>.github.io


Editor branch
----

Create your `editor` branch just typing

	$ git checkout -b editor

###Carew Installation

The best way to start with carew is to use the carew boilerplate: You will need composer.

	$ php composer.phar create-project carew/boilerplate . -s dev
	$ bin/carew build

That's all, you can browse the `web/` directory.

Now you must edit the `confi.yml` and the `posts/` and `pages/` folder contents.

###Git integration

Once your `editor` branch has a carew project working, it's time to integrate it in your workflow. It could be done just by adding two more files to the `editor` branch: `.gitignore` and `install`.

`.gitignore` will prevent you from adding the `bin/` and `vendor/` folders

	/vendor/
	/bin/

Also, `install` will be useful when you want to install your `editor` environment after a `git clone`

	#!/bin/bash
	composer install -o
	bin/carew build

Remeber to add execution permisions

	chmod +x install

Now you can add the root folder into git.

In future checkouts from scratch, you will need to run the `install` script before be ready to work!

	$ git clone https://github.com/kpacha/kpacha.github.io.git
	$ git checkout editor
	$ ./install

Master branch
----

Checkout your `master` branch

	$ git checkout master

And add the `.gitignore` file from the `editor` branch

	$ git checkout editor -- .gitignore

Create a file called `update.sh`

	#!/bin/bash
	git checkout editor -- web
	cp -rp web/* .
	rm -rf web
	git reset HEAD web
	git status

After adding the execution permissions to `update.sh`, add them to git

	$ chmod +x update.sh
	$ git add .gitignore update.sh
	$ git commit -m "set up the master branch"

Now, every time you want to push your generated statics you must run the `update.sh` script, add the untracked files listed, commit them and push the branch to github

Posting
----

From the `editor` branch, create your post entry

    $ bin/carew generate:post "New post title"

Edit your entry and rebuild your web

	$ bin/carew build

Now it's time to commit your changes into your `editor` branch and update your `master` one. Just type

	$ git add .
	$ git commit -m "adding the 'New post title'"
	$ git checkout master
	$ ./update.sh
	$ git add .
	$ git commit -m "publishing the 'New post title'"
	$ git push origin editor
	$ git push origin master

And you're done!
