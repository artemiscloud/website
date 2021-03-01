---
title: "Accessing Broker Management Console from outside Kubernetes"  
type: "regular"
description: "A demo case of exposing broker console via K8s ingress with ArtemisCloud Operator"
draft: false
---
With ArtemisCloud operator you can choose to expose the management console of a deployed broker so that it can be connected from outside the kubernetes cluster.

### About the Management Console
Apache ActiveMQ Artemis broker comes with a web-based management console powered by [Hawt.io](http://hawt.io). The broker hosts the management console in an embedded jetty server and listening on HTTP port 8161 (default port).

When the broker runs in a pod, however, it can't be accessed directly from outside the cluster unless we configure properly.

With the operator the broker management console can be secured with HTTPS and login accounts. We'll demonstrate how.

### Prerequisite
Before you start you need have access to a running Kubernetes cluster environment(or an Openshift cluster). A [Minikube](https://minikube.sigs.k8s.io/docs/start/) running on your laptop will just do fine. The ArtemisCloud operator also runs in a Openshift cluster environment like [CodeReady Container](https://developers.redhat.com/products/codeready-containers/overview). In this blog we introduce ways to expose the broker management console in both Kubernetes cluster and openshift environment.

### Enable Ingress Controller in Minikube
If you are using Minikube you need first to enable the ingress controller before
deploying the CR if you haven't done so already. To enable ingress run the following
command:
```shell script
minikube addons enable ingress
```
To verify that the ingress controller is active, run the command and check the output:
```shell script
kubectl get pods -n kube-system
NAME                                        READY   STATUS      RESTARTS   AGE
...
ingress-nginx-controller-558664778f-8prxb   1/1     Running     2          32h
...
```

### Deploy the ArtemisCloud Operator
First you need to deploy the ArtemisCloud operator.
If you are not sure how to deploy the operator take a look at [this blog]({{< relref "/blog/using_operator.md" >}}).

Assume you deployed the operator to a namespace called **myproject**.

Make sure the operator is in "Running" status before going to the next step.
You can run this command and observe the output:

```shell script
$ kubectl get pod -n myproject
NAME                                         READY   STATUS    RESTARTS   AGE
activemq-artemis-operator-6657d9859f-k2zrd   1/1     Running   0          25m
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
Notice in the yaml file we define **expose: true** under **console** property. It means to expose the management console via ingress.

### Deploy Broker Custom resource
Run the following command to deploy the CR just created:
```shell script
$ kubectl create -f broker-console.yaml -n myproject
activemqartemis.broker.amq.io/ex-aao created
```
and checking that the broker pod is up and running:
```shell script
$ kubectl get pod -n myproject
NAME                                         READY   STATUS    RESTARTS   AGE
activemq-artemis-operator-6657d9859f-k2zrd   1/1     Running   0          3h18m
ex-aao-ss-0                                  1/1     Running   0          4m11s
```
Now you can check out details about the ingress:
```shell script
$ kubectl get ingress -n myproject
NAME                      CLASS    HOSTS   ADDRESS          PORTS   AGE
ex-aao-wconsj-0-svc-ing   <none>   *       192.168.99.116   80      12h
```
Notice the **ADDRESS** and **PORTS** fields. They tell that the ingress is
listening on 192.168.99.116:80. For Minikube the IP address is only meaningful
within the host where it is installed.

On the minikube host open a browser and go to **http://192.168.99.116** (port omitted as it's default http port) and you'll see the management console's front page:

![The management console](/website/images/blog/mgmt-console/console-http.png)

Click "Management Console" and the login page is shown. As in this deployment anonymous login is allowed, just arbitrary username/password will do.

Explore the various links after you log in.

### Secure the Management console
It is recommended that the broker management console should be accessed with a valid account and the communication should be secured with SSL (https) in a production environment.

Ingress supports HTTPS communications over port 443. The TLS termination at ingress point so the communication between ingress and the backend services (e.g. the management console) are plain HTTP.

A few more options are needed in the broker CR to make a secured management console.

First undeploy the previous broker CR.

```shell script
$ kubectl delete -f broker-console.yaml -n myproject
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
In the above broker CR file we explicitly configure a **adminUser** and a **adminPassword** which will be used to log in the console. Also there are two more new parameters that are used for secure the ingress point:

- **sslEanbled** Setting it to true to let operator to configure a https ingress.
- **sslSecret** This is the name of the secret that the ingress is used for its certificate and key files.

As you see that the above **sslSecret** is set to **console-secret** which must exist before deployment. Now let's create it.

First let's generate a self-signed certificate file and a key file.
```shell script
$ openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout consolekey -out consolecert -subj "/CN=www.mgmtconsole.com/O=www.mgmtconsole.com"
Generating a RSA private key
..........+++++
..................................................................+++++
writing new private key to 'consolekey'
-----
```
The above command generates a cert file **consolecert** and a key file **consolekey** under the current dir. Note that the value of CN is **www.mgmtconsole.com** which later we take as the management console's host name in its url.

Now with the cert file and key file generated let's create the needed secret **console-secret**:
```shell script
$ kubectl create secret tls console-secret --key consolekey --cert consolecert -n myproject
secret/console-secret created
```
Verify the secret is created:
```shell script
$ kubectl get secret -n myproject
NAME                                    TYPE                                  DATA   AGE
activemq-artemis-operator-token-6zmg9   kubernetes.io/service-account-token   3      3d19h
console-secret                          kubernetes.io/tls                     2      5m18s
default-token-2mrq9                     kubernetes.io/service-account-token   3      3d22h
```
Then deploy the broker:
```shell script
$ kubectl create -f broker-console-secured.yaml -n myproject
activemqartemis.broker.amq.io/ex-aao created
```
Wait for the pod to be in **RUNNING** status. To check the status you can run the following command:

```shell script
$ kubectl get pod -n myproject
NAME                                         READY   STATUS    RESTARTS   AGE
activemq-artemis-operator-6fcbbb75f8-vs4hg   1/1     Running   0          51m
ex-aao-ss-0                                  1/1     Running   0          95s
```
At this moment there will be an ingress object created for us. To check it out use the following command and see the ouput:
```shell script
$ kubectl get ingress -n myproject
NAME                      CLASS    HOSTS                 ADDRESS          PORTS     AGE
ex-aao-wconsj-0-svc-ing   <none>   www.mgmtconsole.com   192.168.99.116   80, 443   3m51s

```
The above output shows the ingress is ready and available through HTTPS port 443.

You may have noticed that the http default port 80 is also available. If you try visit the management console using http rather https the ingress will redirect you to https.

Before we can open up the browser and visit the management console, there is one more thing to do with minikube. As in the certificate we set up the host to be **www.mgmtconsole.com** which is a 'fake' DNS name. When you input that 'fake' host name in the browser it should be resolved properly. To do that we can add the host name to the /etc/hosts file on the local machine which runs the Minikube.

Open the **/etc/hosts** with root permissions (e.g. using sudo) and append the following record to the file.
```
192.168.99.116 www.mgmtconsole.com
```
where **192.168.99.116** being the Minikube's IP.

Now at the Minikube local machine open up your browser and go "https://www.mgmtconsole.com". Because our ingress has a self-signed certificate the browser often prompts to you a message saying that the site is not trusted. Ignore the message and choose the option to go ahead.

You will see the front page of the management console.

![The management console](/website/images/blog/mgmt-console/console-front-ssl.png)

When the front page shows up click on **Management Console** and it brings you to the login page.

![The management console](/website/images/blog/mgmt-console/console-login-ssl.png)

You need to use the username/password defined in the CR to log in.
Input **consoleadmin** as Username and **consolepassword** as Password and then click login. The main management web page will show up. Try click on different links and tabs in it to explore.

![The management console](/website/images/blog/mgmt-console/console-main-ssl.png)

Now you have successfully secured your management console.

### Further information

* [ArtemisCloud Github Repo](https://github.com/artemiscloud)
* For more information on ActiveMQ Artemis please read the [Artemis Documentation](https://activemq.apache.org/components/artemis/documentation/)
