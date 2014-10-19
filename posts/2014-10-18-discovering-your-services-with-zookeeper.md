---
layout: post
title:  Discovering your services with ZooKeeper
tags:
    - java
    - php
    - zookeeper
    - suricate
    - service discovering
---

This is the first of a several articles I am planing to write about service discovering in PHP environments, so let's start it.

The problem
----

Almost all apps needs to interact with external services (like databases or REST services). It's a fact. And they need some way to identify those services and the nodes that conform them. Usually, you put this info in a config file and your code just reads that file in order to know the database connection details.

The naive aproach described in the previous block has an important cons: it does not scale because every update requires a new deployment (due you're mixing code with configuration) of all the affected node (all the services depending on the updated ones)

The solution
----

As the [official website](http://zookeeper.apache.org/) says: *"ZooKeeper is a centralized service for maintaining configuration information, naming, providing distributed synchronization, and providing group services"*. Why don't we delegate all the hard work to it?

ZooKeeper is a very raw tool, so I'd rather go with the [Curator](http://curator.apache.org/index.html) framework. It comes with a lot of recipes already implemented. Also, it has two very interesting extensions: 'Service Discovering' and 'Service Discovering Server'.

The 'Service Discovering' system provides a mechanism for:

* Services to register their availability
* Locating a single instance of a particular service
* Notifying when the instances of a service change

The 'Service Discovery Server' bridges non-Java or legacy applications with the Curator Service Discovery exposing RESTful web services to register, remove, query, etc. services.

The architecture is simple: some ZooKeeper nodes will be the backend of the autodiscovering system and the frontend nodes will host an implementation of the 'Service Discovery Server'. Clients will interact with the frontend nodes using a simple curl-based sdk.

REST server implementation
----

The Curator website says *"The Service Discovery Server provides JAX-RS components that can be incorporated into a container of your choice (Tomcat, Jetty, etc.). You can also choose any JAX-RS provider (Jersey, RESTEasy, etc.)."*. So let's try to create a simple jetty-based server exposing the JAX-RS components.

The first step is defining the project dependencies. Using the well-known maven project definition file, we must require the `curator-x-service-discovery`, the `jetty-servlet`, the `jersey-servlet` and the `jersey-core`. Also, we should configure the `exec-maven-plugin` and the `maven-assembly-artifact` in order to buld an executable fat-jar.

        <project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
            <modelVersion>4.0.0</modelVersion>
            <groupId>com.github.kpacha</groupId>
            <artifactId>suricate</artifactId>
            <version>0.0.2-SNAPSHOT</version>

            <properties>
                    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
                    <project.reporting.outputEncoding>UTF-8</project.reporting.outputEncoding>
                    <jetty.version>9.1.1.v20140108</jetty.version>
                    <jersey.version>1.11</jersey.version>
                    <commons-cli.version>1.2</commons-cli.version>
                    <maven-compiler-plugin.version>2.3.2</maven-compiler-plugin.version>
                    <jdk.version>1.7</jdk.version>
            </properties>

            <dependencies>
                    <dependency>
                            <groupId>com.netflix.curator</groupId>
                            <artifactId>curator-x-discovery-server</artifactId>
                            <version>1.3.3</version>
                    </dependency>

                    <dependency>
                            <groupId>org.eclipse.jetty</groupId>
                            <artifactId>jetty-servlet</artifactId>
                            <version>${jetty.version}</version>
                    </dependency>

                    <dependency>
                            <groupId>com.sun.jersey</groupId>
                            <artifactId>jersey-servlet</artifactId>
                            <version>${jersey.version}</version>
                    </dependency>

                    <dependency>
                            <groupId>com.sun.jersey</groupId>
                            <artifactId>jersey-core</artifactId>
                            <version>${jersey.version}</version>
                    </dependency>

                    <dependency>
                            <groupId>commons-cli</groupId>
                            <artifactId>commons-cli</artifactId>
                            <version>${commons-cli.version}</version>
                    </dependency>
            </dependencies>
            <build>
                    <plugins>
                            <plugin>
                                    <groupId>org.mortbay.jetty</groupId>
                                    <artifactId>jetty-maven-plugin</artifactId>
                                    <version>${jetty.version}</version>
                            </plugin>

                            <plugin>
                                    <groupId>org.codehaus.mojo</groupId>
                                    <artifactId>exec-maven-plugin</artifactId>
                                    <version>1.1</version>
                                    <executions>
                                            <execution>
                                                    <goals>
                                                            <goal>java</goal>
                                                    </goals>
                                            </execution>
                                    </executions>
                                    <configuration>
                                            <mainClass>com.github.kpacha.suricate.Suricate</mainClass>
                                    </configuration>
                            </plugin>

                            <plugin>
                                    <artifactId>maven-assembly-plugin</artifactId>
                                    <version>2.4</version>
                                    <configuration>
                                            <descriptorRefs>
                                                    <descriptorRef>jar-with-dependencies</descriptorRef>
                                            </descriptorRefs>
                                            <archive>
                                                    <manifest>
                                                            <mainClass>com.github.kpacha.suricate.Suricate</mainClass>
                                                    </manifest>
                                            </archive>
                                    </configuration>
                            </plugin>

                            <plugin>
                                    <groupId>org.apache.maven.plugins</groupId>
                                    <artifactId>maven-compiler-plugin</artifactId>
                                    <version>${maven-compiler-plugin.version}</version>
                                    <configuration>
                                            <source>${jdk.version}</source>
                                            <target>${jdk.version}</target>
                                    </configuration>
                            </plugin>
                    </plugins>
            </build>
        </project>

Next, we must create a StringDiscoveryResource extending DiscoveryResource to bind the path "/" to the ContextResolver. Not funny at all.

    @Path("/")
    public class StringDiscoveryResource extends DiscoveryResource<String> {
        public StringDiscoveryResource(
                @Context ContextResolver<DiscoveryContext<String>> resolver) {
            super(resolver.getContext(DiscoveryContext.class));
        }
    }

Now we need to create an Application and set-up the curator framework and the service discovery. The curator framework will setup the connection to the ZooKeeper server. The `ExponentialBackoffRetry` strategy is the recomended one here.

    CuratorFramework curatorFramework = CuratorFrameworkFactory.newClient(
            configuration.getZkConnection(), new ExponentialBackoffRetry(
                    1000, 3));
    curatorFramework.start();

The Application also requires a service discovery instance from the curator framework

    ServiceDiscovery<String> serviceDiscovery = new ServiceDiscoveryImpl<String>(
            curatorFramework, configuration.getZkBasePath(),
            new JsonInstanceSerializer<String>(String.class), null);

Our StringDiscoveryContext has to be instantiate too

    context = new StringDiscoveryContext(serviceDiscovery,
            new RandomStrategy<String>(),
            configuration.getInstanceCleanupMillis());

And the thread responsible for cleaning up the evicted STATIC nodes

    instanceCleanup = new InstanceCleanup(serviceDiscovery,
            configuration.getInstanceCleanupMillis());
    instanceCleanup.start();

Since we want to work with json encoded payloads, we must set up the json service instance marshaller

    serviceInstanceMarshaller = new JsonServiceInstanceMarshaller<String>(context);
    serviceInstancesMarshaller = new JsonServiceInstancesMarshaller<String>(context);

After playing with very boring stuff like the getSingletons() implementation and registering the StringDiscoveringResource, the [Application](https://github.com/kpacha/suricate/blob/master/src/main/java/com/github/kpacha/suricate/Application.java) comes out.

Time to coordinate the Application with the JettyServer! Pass the injected Application to the ServletContainer and register the context path and bind the servlet to the route "/*".

    public void run() throws Exception {
            ServletContainer container = new ServletContainer(app);

            server = new Server(port);

            ServletContextHandler context = new ServletContextHandler(
                    ServletContextHandler.SESSIONS);
            context.setContextPath("/");
            server.setHandler(context);
            context.addServlet(new ServletHolder(container), "/*");

            server.start();
            server.join();
    }

The final step is to create a Main class with the static main method to create the Application and run the JettyServer.

    public static void main(String[] args) throws Exception {
            Configuration config = new Configuration(args);
            JettyServer jetty = new JettyServer(new Application(config),
                    config.getPort());
            jetty.run();
    }

I am sure you have already detected I also created a [Config](https://github.com/kpacha/suricate/blob/master/src/main/java/com/github/kpacha/suricate/Configuration.java) class to encapsulate all the command line manipulation, so the Application remains as client agnostic as possible.

The complete [suricate project](https://github.com/kpacha/suricate) is available on github. If you do not want any further customization, it could get the job done!

Setting up your environment
----

In devel, you just need to get a single ZooKeeper server running. Check the [quick start help](http://zookeeper.apache.org/doc/trunk/zookeeperStarted.html) to get it done. Once you have your config, just run

    $ /path/to/zk/$ bin/zkServer.sh start
    JMX enabled by default
    Using config: /home/kpacha/zookeeper/zookeeper-3.4.6/bin/../conf/zoo.cfg
    Starting zookeeper ... STARTED


in production environments, you must think about what replication startegy fits you best. The complete documentation is [here](http://zookeeper.apache.org/doc/trunk/zookeeperAdmin.html#sc_zkMulitServerSetup). Remember to properly set up your suricate servers to we aware of the multiserver architecture you are using.

Running the REST Server
----

Follow [this instructions](https://github.com/kpacha/suricate#build-and-run-the-fat-jar) to build the fat-jar and then start the suricate server with

    $ java -jar /path/to/suricate/target/suricate-0.0.2-SNAPSHOT-jar-with-dependencies.jar
     INFO [main] (Configuration.java:86) - Param [p]: 8080
     INFO [main] (Configuration.java:75) - Param [c]: 127.0.0.1:2181
     INFO [main] (Configuration.java:75) - Param [b]: /suricate/service-directory
     INFO [main] (Configuration.java:86) - Param [t]: 15000
    DEBUG [main] (Application.java:35) - Curator framework started!
     WARN [ConnectionStateManager-0] (ConnectionStateManager.java:174) - There are no ConnectionStateListeners registered.
    DEBUG [main] (Application.java:40) - ServiceDiscovery started!
    DEBUG [main] (Application.java:45) - DiscoveryContext started!
    DEBUG [main] (Application.java:50) - SuricateInstanceCleanup started!
    DEBUG [main] (Application.java:56) - Json marshallers started!
    oct 19, 2014 5:53:36 PM com.sun.jersey.server.impl.application.WebApplicationImpl _initiate
    INFO: Initiating Jersey application, version 'Jersey: 1.11 12/09/2011 10:27 AM'

All the options are documented at the home of the project (https://github.com/kpacha/suricate#usage)
