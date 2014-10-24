---
layout: post
title:  Creating your sdk for suricate
tags:
    - php
    - zookeeper
    - suricate
    - service discovering
---

This is the second article of the *service discovering in PHP environments* serie. The {{ link('posts/2014-10-18-discovering-your-services-with-zookeeper.md', 'first one') }} was about implementing a Curator Service Discovering REST Server. This will be about creating a simple sdk to provide a nice integration to the autodiscovering service to your clients.

The REST interface
----

The rest interface is defined in the homepage of the [suricate project](https://github.com/kpacha/suricate#usage).

TLDR? here goes the short version:

    # Register the host 'ca2fff8e-d756-480c-b59e-8297ff88624b' in the cluster 'test'
    $ curl -i -H "Accept: application/json" -H "Content-Type: application/json" -X PUT -d '{"name": "test", "id": "ca2fff8e-d756-480c-b59e-8297ff88624b", "address": "10.20.30.40", "port": 1234, "payload": "supu", "registrationTimeUTC": 1325129459728, "serviceType": "STATIC"}' http://localhost:8080/v1/service/test/ca2fff8e-d756-480c-b59e-8297ff88624b

    # Get all registered services
    $ curl -i http://localhost:8080/v1/service

    # Get all nodes in 'test' service
    $ curl -i http://localhost:8080/v1/service/test

    # Get the node 'ca2fff8e-d756-480c-b59e-8297ff88624b' of the 'test' service
    $ curl -i http://localhost:8080/v1/service/test/ca2fff8e-d756-480c-b59e-8297ff88624b
    

    # Get the node 'ca2fff8e-d756-480c-b59e-8297ff88624b' of the 'test' service
    $ curl -i -X DELETE http://localhost:8080/v1/service/test/ca2fff8e-d756-480c-b59e-8297ff88624b

As you must seen, the data structure is

*ServiceInstance*

    {
       "name": "test",
       "id": "ca2fff8e-d756-480c-b59e-8297ff88624b",
       "address": "10.20.30.40",
       "port": 1234,
       "payload": "From Test",
       "registrationTimeUTC": 1325129459728,
       "serviceType": "STATIC"
    }

*ServiceInstances*

    [
        {
           "name": "test",
           "id": "ca2fff8e-d756-480c-b59e-8297ff88624b",
           "address": "10.20.30.40",
           "port": 1234,
           "payload": "From Test",
           "registrationTimeUTC": 1325129459728,
           "serviceType": "STATIC"
        },

        {
           "name": "foo",
           "id": "bd4fff8e-c234-480c-f6ee-8297ff813765",
           "address": "10.20.30.40",
           "sslPort": 1235,
           "payload": "foo-bar",
           "registrationTimeUTC": 1325129459728,
           "serviceType": "STATIC"
        }
    ]

*ServiceNames*

    [
        {
            "name": "foo"
        },

        {
            "name": "bar"
        }
    ]

The REST client
----

Once you are familiar with the REST interface, it's time to build the client. I did it in php, with great help of the Guzzle lib.

First of all, the package dependencies. I created a REST client and CLI interface, so there were my dependencies:

    {
        ...
        "require": {
            "php": ">=5.3.3",
            "symfony/console": "~2.4",
            "guzzle/guzzle":"~3.7"
        },
        ...
    }

The suricate client must expose the metods the REST interface encasulates, so it has to implement this 'interface':

    abstract public function getAllNames();

    abstract public function getAll($service);

    abstract public function get($service, $id);

    abstract public function putService($service, $id, $node);

    abstract public function removeService($service, $id);

My implementation of this 'interface' is [here](https://github.com/kpacha/suricate-php-sdk/blob/master/src/Suricate.php).

Whith your implementation, you'll be able to interact with the REST service discovering server easily

    $client = ... // instantiate your implementation

    $success = $client->putService($serviceName, $nodeId, $node);
    $serviceNames = $client->getAllNames();
    $nodes = $client->getAll($serviceName);
    $node = $client->get($serviceName, $nodeId);
    $success = $client->removeService($serviceName, $nodeId);

The [suricate-php-sdk](https://github.com/kpacha/suricate-php-sdk) also offers a set of commands to interact to de REST server through the CLI.

Coming soon: getting more from the sdk and integrating the service discovering with your local configuration