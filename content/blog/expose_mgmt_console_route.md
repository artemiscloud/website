---
title: "Accessing Broker Management Console from outside Openshift"  
type: "regular"
description: "A demo case of exposing broker console via Openshift route object with ArtemisCloud Operator"
draft: false
---
With ArtemisCloud operator you can choose to expose the management console of a deployed broker so that it can be connected from outside the Openshift cluster.

In [another article]({{< relref "/blog/expose_mgmt_console.md" >}}). we described how to expose the management console from a Kubernetes cluster using ingress.
In an Openshift environment it still use the same configuration. Similarly we can expose the management console via plain HTTP protocol with anonymous log in and via HTTPS protocol with a credential. However under the hood the management console is exposed by [Route](https://docs.openshift.com/container-platform/3.9/architecture/networking/routes.html). We'll explain more details later on.

### Prerequisite
Before you start you need have access to a running Openshift cluster environment. For this article we will use [CodeReady Container](https://developers.redhat.com/products/codeready-containers/overview). If you don't have an Openshift cluster already you can follow the instructions on the website to install CodeReady.

### Deploy the ArtemisCloud Operator
Assume you deployed the operator to a project called **myproject**. Use the following command to create it in Openshift:

```shell script
$ oc new-project myproject
Now using project "myproject" on server "https://api.crc.testing:6443".

You can add applications to this project with the 'new-app' command. For example, try:

    oc new-app rails-postgresql-example

to build a new example application in Ruby. Or use kubectl to deploy a simple Kubernetes application:

    kubectl create deployment hello-node --image=k8s.gcr.io/serve_hostname
```
Deploy an ArtemiCloud operator into your project.

If you are not sure how to deploy the operator take a look at [this blog]({{< relref "/blog/using_operator.md" >}}).

Make sure the operator is in "Running" status before going to the next step.
You can run this command and observe the output:

```shell script
$ oc get pod -n myproject
NAME                                         READY   STATUS    RESTARTS   AGE
activemq-artemis-operator-5c86c49f88-fvnjm   1/1     Running   0          10m
```

### Preparing the Broker Custome Resource (CR)
Create a file named "broker-console.yaml" with the following contents:

```yaml
apiVersion: broker.amq.io/v2alpha4
kind: ActiveMQArtemis
metadata:
  name: ex-aao
spec:
  deploymentPlan:
    size: 1
    image: quay.io/artemiscloud/activemq-artemis-broker-kubernetes:0.2.1
  console:
    expose: true
```
Notice in the yaml file we define **expose: true** under **console** property. It means to expose the management console via route in Openshift.

### Deploy Broker Custom resource
Run the following command to deploy the CR just created:
```shell script
$ oc create -f broker-console.yaml -n myproject
activemqartemis.broker.amq.io/ex-aao created
```
and checking that the broker pod is up and running:
```shell script
$ oc get pod -n myproject
NAME                                         READY   STATUS    RESTARTS   AGE
activemq-artemis-operator-6657d9859f-k2zrd   1/1     Running   0          3h18m
ex-aao-ss-0                                  1/1     Running   0          4m11s
```
Now you can check out details about the route:
```shell script
$ oc get route -n myproject
NAME                      HOST/PORT                                            PATH   SERVICES              PORT       TERMINATION   WILDCARD
ex-aao-wconsj-0-svc-rte   ex-aao-wconsj-0-svc-rte-myproject.apps-crc.testing          ex-aao-wconsj-0-svc   wconsj-0                 None

```
Notice the **HOST/PORT** field. It tells that the route is
listening on host **ex-aao-wconsj-0-svc-rte-myproject.apps-crc.testing** and port is default 80.

On the Openshift host open a browser and go to **http://ex-aao-wconsj-0-svc-rte-myproject.apps-crc.testing** (port omitted as it's default http port) and you'll see the management console's front page:

![The management console](/website/images/blog/mgmt-console/console-route-http-front.png)

Different from Minikube, CodeReady modifies the DNS service properly for you so that the host **ex-aao-wconsj-0-svc-rte-myproject.apps-crc.testing** is automatically resolvable on the host machine.

Click "**Management Console**" and the login page is shown. As in this deployment anonymous login is allowed, just arbitrary username/password will do.

Explore the various links after you log in.

### Secure the Management console
It is recommended that the broker management console should be accessed with a valid account and the communication should be secured with SSL (https) in a production environment.

Openshift route supports HTTPS communications like ingress. Unlike ingress however the ArtemisCloud operator sets up a route with [Passthrough Termination](https://docs.openshift.com/container-platform/3.9/architecture/networking/routes.html#passthrough-termination). It means that the TLS termination does not happen at the route, instead the route passes the encrypted traffic directly to the endpoint. In this case it is the broker that handles the TLS processing. This will affects how the certificate is prepared in next steps.

To make the management console secure a few more options are needed. But First undeploy the previous broker CR.

```shell script
$ oc delete -f broker-console.yaml -n myproject
activemqartemis.broker.amq.io "ex-aao" deleted
```

Create another custom resource file "broker-console-secured.yaml" with the following content:

```yaml
apiVersion: broker.amq.io/v2alpha4
kind: ActiveMQArtemis
metadata:
  name: ex-aao
spec:
  deploymentPlan:
    size: 1
    image: quay.io/artemiscloud/activemq-artemis-broker-kubernetes:0.2.1
    requireLogin: true
  console:
    expose: true
    sslEnabled: true
    sslSecret: console-secret
  adminUser: consoleadmin
  adminPassword: consolepassword
```
In the above broker CR file we explicitly configure a **adminUser** and a **adminPassword** which will be used to log in the console. Also there are two more new parameters that are used for secure the route point:

- **sslEanbled** Setting it to true to let operator to configure a https transport via route.
- **sslSecret** This is the name of the secret that the broker is used for the management console.

As you see that the above **sslSecret** is set to **console-secret** which must exist before deployment. Now let's create it.

The secret must contain a keystore and the keystore's password. Here we use the [keytool](https://docs.oracle.com/javase/8/docs/technotes/tools/unix/keytool.html) that comes with Java Development Kit(JDK).

```shell script
$ keytool -genkeypair -alias amq7 -keyalg RSA -keysize 2048 -storetype PKCS12 -keystore broker.ks -validity 3000
Enter keystore password:  
Re-enter new password:
What is your first and last name?
  [Unknown]:  Howard Gao
What is the name of your organizational unit?
  [Unknown]:  Red Hat
What is the name of your organization?
  [Unknown]:  Red Hat
What is the name of your City or Locality?
  [Unknown]:  Beijing
What is the name of your State or Province?
  [Unknown]:  Beijing
What is the two-letter country code for this unit?
  [Unknown]:  CN
Is CN=Howard Gao, OU=Red Hat, O=Red Hat, L=Beijing, ST=Beijing, C=CN correct?
  [no]:  yes
```
As shown above the **keytool** will ask you some questions in order to generate the keystore file. The first question is the password for the keystore. Assume the password is **password**.

When the above command completed it generates a keystore file called "**broker.ks**" in the current directory.

Now we create the needed secret **console-secret** with the generated keystore and keystore password:
```shell script
$ oc create secret generic console-secret --from-file=broker.ks --from-literal=keyStorePassword='password' -n myproject
secret/console-secret created
```

Then deploy the broker:
```shell script
$ oc create -f broker-console-secured.yaml -n myproject
activemqartemis.broker.amq.io/ex-aao created
```
Wait for the pod to be in **RUNNING** status. To check the status you can run the following command:

```shell script
$ oc get pod -n myproject
NAME                                         READY   STATUS    RESTARTS   AGE
activemq-artemis-operator-5c86c49f88-fvnjm   1/1     Running   0          6h23m
ex-aao-ss-0                                  1/1     Running   0          115s
```
At this moment there should be a route object created for us. To check it out use the following command and see the ouput:
```shell script
$ oc get route -n myproject
NAME                      HOST/PORT                                            PATH   SERVICES              PORT       TERMINATION        WILDCARD
ex-aao-wconsj-0-svc-rte   ex-aao-wconsj-0-svc-rte-myproject.apps-crc.testing          ex-aao-wconsj-0-svc   wconsj-0   passthrough/None   None
```
As with the plain HTTP case the route provides us with a host name **ex-aao-wconsj-0-svc-rte-myproject.apps-crc.testing**. What's different is that the **TERMINATION** field now has value **passthrough/None**. It means when we visit the management console through the route it passes the request directly to the broker's embedded web server which will eventually handles all the TLS operations.

Now at the CodeReady hosting machine open up your browser and go to "https://ex-aao-wconsj-0-svc-rte-myproject.apps-crc.testing". Because we use a self-signed certificate the browser often prompts to you a message saying that the site is not trusted. Ignore the message and choose the option to go ahead.

You will see the front page of the management console.

![The management console](/website/images/blog/mgmt-console/console-route-front-ssl.png)

When the front page shows up click on **Management Console** and it brings you to the login page.

![The management console](/website/images/blog/mgmt-console/console-route-login-ssl.png)

You need to use the username/password defined in the CR to log in.
Input **consoleadmin** as Username and **consolepassword** as Password and then click login. The main management web page will show up. Try click on different links and tabs in it to explore.

![The management console](/website/images/blog/mgmt-console/console-route-main-ssl.png)

Now you have successfully secured your management console in Openshift.

### Further information

* [ArtemisCloud Github Repo](https://github.com/artemiscloud)
* For more information on ActiveMQ Artemis please read the [Artemis Documentation](https://activemq.apache.org/components/artemis/documentation/)
