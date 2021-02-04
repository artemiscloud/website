---
title: "Getting Started with the ArtemisCloud Operator"  
type: "featured"
description: "Steps to get operator up and running and basic broker operations"
draft: false
---
The [ArtemisCloud](https://github.com/artemiscloud) Operator is a powerful tool that allows you to configure and
manage ActiveMQ Artemis broker resources in a cloud environment. You can get it up and running in just a few steps.

### Prerequisite
Before you start you need have access to a running Kubernetes cluster environment. A [Minikube](https://minikube.sigs.k8s.io/docs/start/)
running on your laptop will just do fine. The ArtemisCloud operator also runs in a Openshift cluster environment
like [CodeReady Container](https://developers.redhat.com/products/codeready-containers/overview). In this blog we assume
you have Kubernetes cluster environment. (If you use CodeReady the client tool is **oc** in place of **kubectl**)

### Step 1 - Preparing for deployment
* Clone the ArtemisCloud operator repo:
```shell script
      $ git clone https://github.com/artemiscloud/activemq-artemis-operator.git
```
* Go to the local repo root and set up related account and permissions needed for operator deployment.
```shell script      
      $ cd activemq-artemis-operator
      $ kubectl create -f deploy/service_account.yaml
      $ kubectl create -f deploy/role.yaml
      $ kubectl create -f deploy/role_binding.yaml
```
* Deploy all the CRDs that the operator supports.
```shell script   
      # the broker crd
      $ kubectl create -f deploy/crds/broker_activemqartemis_crd.yaml
      # the address crd
      $ kubectl create -f deploy/crds/broker_activemqartemisaddress_crd.yaml
      # the scaledown crd
      $ kubectl create -f deploy/crds/broker_activemqartemisscaledown_crd.yaml
```      

> **_NOTE:_**    If you see some warning messages while deploying the crds like:
    *"Warning: apiextensions.k8s.io/v1beta1 CustomResourceDefinition is deprecated in v1.16+, unavailable in v1.22+; use
    apiextensions.k8s.io/v1 CustomResourceDefinition customresourcedefinition.apiextensions.k8s.io/activemqartemises.broker.amq.io created"*
    You can safely ignore them.

### Step 2 - Deploying the operator
Run the command to deploy the operator:
```shell script
      $ kubectl create -f deploy/operator.yaml
```
After that you may need a few moment for the operator to fully start.
You can verify the operator status by running the command and looking at the output:
```shell script
      $ kubectl get pod
      NAME                                         READY   STATUS    RESTARTS   AGE
      activemq-artemis-operator-58bb658f4c-cjqvk   1/1     Running   0          104s
```
Make sure the **STATUS** is **Running**.

### Step 3 - Deploying ActiveMQ Artemis Broker in Cloud
Now with a running operator, it's time to deploy the broker. Run:
```shell script
      kubectl create -f deploy/examples/artemis-basic-deployment.yaml
```
and watch the broker pod to start up:
```shell script
      $ kubectl get pod
      NAME                                         READY   STATUS    RESTARTS   AGE
      activemq-artemis-operator-58bb658f4c-cjqvk   1/1     Running   1          12h
      ex-aao-ss-0                                  1/1     Running   0          85s
```
What happened behind the scene is that the operator watches the CR deployment in the target namespace and when the broker CR is deployed the operator will configure and deploy the broker pod into the cluster.

To see some details of the broker pod startup you can get the console log
from the pod:
```shell script
      $ kubectl logs ex-aao-ss-0
      -XX:+UseParallelOldGC -XX:MinHeapFreeRatio=10 -XX:MaxHeapFreeRatio=20 -XX:GCTimeRatio=4 -XX:AdaptiveSizePolicyWeight=90 -XX:MaxMetaspaceSize=100m -XX:+ExitOnOutOfMemoryError
      Removing provided -XX:+UseParallelOldGC in favour of artemis.profile provided option
      Running server env: home: /home/jboss AMQ_HOME /opt/amq CONFIG_BROKER false RUN_BROKER
      NO RUN_BROKER defined
      Using custom configuration. Copy from /amq/init/config to /home/jboss/amq-broker
      bin
      data
      etc
      lib
      log
      tmp
      Running Broker in /home/jboss/amq-broker
      OpenJDK 64-Bit Server VM warning: If the number of processors is expected to increase from one, then you should configure the number of parallel GC threads appropriately using -XX:ParallelGCThreads=N
           _        _               _
          / \  ____| |_  ___ __  __(_) _____
         / _ \|  _ \ __|/ _ \  \/  | |/  __/
        / ___ \ | \/ |_/  __/ |\/| | |\___ \
       /_/   \_\|   \__\____|_|  |_|_|/___ /
       Apache ActiveMQ Artemis 2.16.0


      2021-02-03 03:30:38,244 INFO  [org.apache.activemq.artemis.integration.bootstrap] AMQ101000: Starting ActiveMQ Artemis Server
      2021-02-03 03:30:38,334 INFO  [org.apache.activemq.artemis.core.server] AMQ221000: live Message Broker is starting with configuration Broker Configuration (clustered=true,journalDirectory=data/journal,bindingsDirectory=data/bindings,largeMessagesDirectory=data/large-messages,pagingDirectory=data/paging)
      2021-02-03 03:30:38,485 INFO  [org.apache.activemq.artemis.core.server] AMQ221013: Using NIO Journal
      2021-02-03 03:30:38,673 INFO  [org.apache.activemq.artemis.core.server] AMQ221057: Global Max Size is being adjusted to 1/2 of the JVM max size (-Xmx). being defined as 1,045,430,272
      2021-02-03 03:30:39,126 WARNING [org.jgroups.stack.Configurator] JGRP000014: BasicTCP.use_send_queues has been deprecated: will be removed in 4.0
      2021-02-03 03:30:39,160 WARNING [org.jgroups.stack.Configurator] JGRP000014: Discovery.timeout has been deprecated: GMS.join_timeout should be used instead
      2021-02-03 03:30:39,276 INFO  [org.jgroups.protocols.openshift.DNS_PING] serviceName [ex-aao-ping-svc] set; clustering enabled
      2021-02-03 03:30:42,381 INFO  [org.openshift.ping.common.Utils] 3 attempt(s) with a 1000ms sleep to execute [GetServicePort] failed. Last failure was [javax.naming.NameNotFoundException: DNS name not found [response code 3]]
      2021-02-03 03:30:42,383 WARNING [org.jgroups.protocols.openshift.DNS_PING] No DNS SRV record found for service [ex-aao-ping-svc]

      -------------------------------------------------------------------
      GMS: address=ex-aao-ss-0-55398, cluster=activemq_broadcast_channel, physical address=172.17.0.4:7800
      -------------------------------------------------------------------
      2021-02-03 03:30:45,588 INFO  [org.apache.activemq.artemis.core.server] AMQ221043: Protocol module found: [artemis-server]. Adding protocol support for: CORE
      2021-02-03 03:30:45,594 INFO  [org.apache.activemq.artemis.core.server] AMQ221043: Protocol module found: [artemis-amqp-protocol]. Adding protocol support for: AMQP
      2021-02-03 03:30:45,596 INFO  [org.apache.activemq.artemis.core.server] AMQ221043: Protocol module found: [artemis-hornetq-protocol]. Adding protocol support for: HORNETQ
      2021-02-03 03:30:45,597 INFO  [org.apache.activemq.artemis.core.server] AMQ221043: Protocol module found: [artemis-mqtt-protocol]. Adding protocol support for: MQTT
      2021-02-03 03:30:45,599 INFO  [org.apache.activemq.artemis.core.server] AMQ221043: Protocol module found: [artemis-openwire-protocol]. Adding protocol support for: OPENWIRE
      2021-02-03 03:30:45,600 INFO  [org.apache.activemq.artemis.core.server] AMQ221043: Protocol module found: [artemis-stomp-protocol]. Adding protocol support for: STOMP
      2021-02-03 03:30:45,712 INFO  [org.apache.activemq.artemis.core.server] AMQ221034: Waiting indefinitely to obtain live lock
      2021-02-03 03:30:45,712 INFO  [org.apache.activemq.artemis.core.server] AMQ221035: Live Server Obtained live lock
      2021-02-03 03:30:45,901 INFO  [org.apache.activemq.artemis.core.server] AMQ221080: Deploying address DLQ supporting [ANYCAST]
      2021-02-03 03:30:45,942 INFO  [org.apache.activemq.artemis.core.server] AMQ221003: Deploying ANYCAST queue DLQ on address DLQ
      2021-02-03 03:30:46,083 INFO  [org.apache.activemq.artemis.core.server] AMQ221080: Deploying address ExpiryQueue supporting [ANYCAST]
      2021-02-03 03:30:46,086 INFO  [org.apache.activemq.artemis.core.server] AMQ221003: Deploying ANYCAST queue ExpiryQueue on address ExpiryQueue
      2021-02-03 03:30:46,493 INFO  [org.apache.activemq.artemis.core.server] AMQ221020: Started EPOLL Acceptor at ex-aao-ss-0.ex-aao-hdls-svc.default.svc.cluster.local:61616 for protocols [CORE]
      2021-02-03 03:30:46,497 INFO  [org.apache.activemq.artemis.core.server] AMQ221007: Server is now live
      2021-02-03 03:30:46,497 INFO  [org.apache.activemq.artemis.core.server] AMQ221001: Apache ActiveMQ Artemis Message Broker version 2.16.0 [amq-broker, nodeID=2f1c2aa0-65d0-11eb-ac82-0242ac110004]
      2021-02-03 03:30:47,246 INFO  [org.apache.activemq.hawtio.branding.PluginContextListener] Initialized activemq-branding plugin
      2021-02-03 03:30:47,371 INFO  [org.apache.activemq.hawtio.plugin.PluginContextListener] Initialized artemis-plugin plugin
      2021-02-03 03:30:48,040 INFO  [io.hawt.HawtioContextListener] Initialising hawtio services
      2021-02-03 03:30:48,104 INFO  [io.hawt.system.ConfigManager] Configuration will be discovered via system properties
      2021-02-03 03:30:48,116 INFO  [io.hawt.jmx.JmxTreeWatcher] Welcome to Hawtio 2.11.0
      2021-02-03 03:30:48,131 INFO  [io.hawt.web.auth.AuthenticationConfiguration] Starting hawtio authentication filter, JAAS realm: "activemq" authorized role(s): "admin" role principal classes: "org.apache.activemq.artemis.spi.core.security.jaas.RolePrincipal"
      2021-02-03 03:30:48,169 INFO  [io.hawt.web.proxy.ProxyServlet] Proxy servlet is disabled
      2021-02-03 03:30:48,182 INFO  [io.hawt.web.servlets.JolokiaConfiguredAgentServlet] Jolokia overridden property: [key=policyLocation, value=file:/home/jboss/amq-broker/etc/jolokia-access.xml]
      2021-02-03 03:30:48,332 INFO  [org.apache.activemq.artemis] AMQ241001: HTTP Server started at http://ex-aao-ss-0.ex-aao-hdls-svc.default.svc.cluster.local:8161
      2021-02-03 03:30:48,333 INFO  [org.apache.activemq.artemis] AMQ241002: Artemis Jolokia REST API available at http://ex-aao-ss-0.ex-aao-hdls-svc.default.svc.cluster.local:8161/console/jolokia
      2021-02-03 03:30:48,333 INFO  [org.apache.activemq.artemis] AMQ241004: Artemis Console available at http://ex-aao-ss-0.ex-aao-hdls-svc.default.svc.cluster.local:8161/console
```
### Step 4 - Create a Queue with the Operator
Now let's create a message queue in the broker. Run:
```shell script
      kubectl create -f deploy/examples/address-queue-create-auto-removed.yaml
```
The _address-queue-create-auto-removed.yaml_ is another kind of custom resources supported by the ArtemisCloud operator. Below is its content:
```yaml
      apiVersion: broker.amq.io/v2alpha2
      kind: ActiveMQArtemisAddress
      metadata:
      name: ex-aaoaddress
      spec:
      addressName: myAddress0
      queueName: myQueue0
      routingType: anycast
      removeFromBrokerOnDelete: true
```
It tells the operator to create a queue named **myQueue0** on address **myAddress0** on each broker it manages.

After the CR is deployed you can observe the queue on broker:

<a name="queuestat"></a>
```shell script
      $ kubectl exec ex-aao-ss-0 -- /bin/bash /home/jboss/amq-broker/bin/artemis queue stat --user admin --password admin --url tcp://ex-aao-ss-0:61616
      OpenJDK 64-Bit Server VM warning: If the number of processors is expected to increase from one, then you should configure the number of parallel GC threads appropriately using -XX:ParallelGCThreads=N
      Connection brokerURL = tcp://ex-aao-ss-0:61616
      |NAME                     |ADDRESS                  |CONSUMER_COUNT |MESSAGE_COUNT |MESSAGES_ADDED |DELIVERING_COUNT |MESSAGES_ACKED |SCHEDULED_COUNT |ROUTING_TYPE |
      |DLQ                      |DLQ                      |0              |0             |0              |0                |0              |0               |ANYCAST      |
      |ExpiryQueue              |ExpiryQueue              |0              |0             |0              |0                |0              |0               |ANYCAST      |
      |activemq.management.2396ff3b-d2d3-40da-ace1-068f76d55fe0|activemq.management.2396ff3b-d2d3-40da-ace1-068f76d55fe0|1              |0             |0              |0                |0              |0               |MULTICAST    |
      |myQueue0                 |myAddress0               |0              |0             |0              |0                |0              |0               |ANYCAST      |
```

### Step 5 - Sending and Receiving messages
Finally you can send some messages to the broker and receive them. Here we just use the artemis cli tool that comes with the deployed broker instance for the test.

Run the following command to send 100 messages:
```shell script
      $ kubectl exec ex-aao-ss-0 -- /bin/bash /home/jboss/amq-broker/bin/artemis producer --user admin --password admin --url tcp://ex-aao-ss-0:61616 --destination myQueue0::myAddress0 --message-count 100
      OpenJDK 64-Bit Server VM warning: If the number of processors is expected to increase from one, then you should configure the number of parallel GC threads appropriately using -XX:ParallelGCThreads=N
      Connection brokerURL = tcp://ex-aao-ss-0:61616
      Producer ActiveMQQueue[myQueue0::myAddress0], thread=0 Started to calculate elapsed time ...

      Producer ActiveMQQueue[myQueue0::myAddress0], thread=0 Produced: 100 messages
      Producer ActiveMQQueue[myQueue0::myAddress0], thread=0 Elapsed time in second : 0 s
      Producer ActiveMQQueue[myQueue0::myAddress0], thread=0 Elapsed time in milli second : 548 milli seconds
````
Now if you check the queue statistics using the command mentioned in [Step 4](#queuestat) you will see the message count is 100:
```shell script
      $ kubectl exec ex-aao-ss-0 -- /bin/bash /home/jboss/amq-broker/bin/artemis queue stat --user admin --password admin --url tcp://ex-aao-ss-0:61616
      OpenJDK 64-Bit Server VM warning: If the number of processors is expected to increase from one, then you should configure the number of parallel GC threads appropriately using -XX:ParallelGCThreads=N
      Connection brokerURL = tcp://ex-aao-ss-0:61616
      |NAME                     |ADDRESS                  |CONSUMER_COUNT |MESSAGE_COUNT |MESSAGES_ADDED |DELIVERING_COUNT |MESSAGES_ACKED |SCHEDULED_COUNT |ROUTING_TYPE |
      |DLQ                      |DLQ                      |0              |0             |0              |0                |0              |0               |ANYCAST      |
      |ExpiryQueue              |ExpiryQueue              |0              |0             |0              |0                |0              |0               |ANYCAST      |
      |activemq.management.d5a658e6-45bb-4764-a507-6a9c1f62da00|activemq.management.d5a658e6-45bb-4764-a507-6a9c1f62da00|1              |0             |0              |0                |0              |0               |MULTICAST    |
      |myAddress0               |myQueue0                 |0              |100           |100            |0                |0              |0               |ANYCAST      |
      |myQueue0                 |myAddress0               |0              |0             |0              |0                |0              |0               |ANYCAST      |
```
### Further information

* [ArtemisCloud Github Repo](https://github.com/artemiscloud)
