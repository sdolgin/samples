## Application Service Autoscaling Sample

### Stress CPU scenario

In this sample you create an Azure App Service plan which includes an Azure App Service. Then you deploy a basic Asp.Net Core MVC application that you can use to simulate a CPU spike. The App Service plan is configured with a basic S1 SKU (1 core, 1.75 GB) to easily create the conditions for the autoscaling scenario. You can deploy the azure resources by publishing the Web Application, but it's recommended to use the provided ARM template since it has a set of custom autoscale rules.

#### Autoscale rules

For this scenario, the App Service plan Scale-out custom setting is configured with the following rule combination:

Increase instances by 1 count when CPU% > 80
Decrease instances by 1 count when CPU% <= 60


This margin between the scale-out and in and the threshold is recommended, consider this case:

Assuming there is 1 instance to start with. If the average CPU% across instances is 81 (the CPU% usage of the only instance), autoscale scales out adding a second instance. Then over time the CPU% falls to 60. Autoscale's scale-in rule estimates the final state if it were to scale-in. For example, 60 x 2 (current instance count) = 120 / 1 (final number of instances when scaled down) = 120. So autoscale does not scale-in because it would have to scale-out again immediately. Instead, it skips scaling down. The next time autoscale checks, the CPU continues to fall to 30%. It estimates again - 30 x 2 instance = 60 / 1 instance = 60, which is below the scale-out threshold of 80, so it scales in successfully to 1 instance.

The duration is set to 5 minutes. This is amount of time that Autoscale engine will look back for metrics. So in this case, 5 minutes means that every time autoscale runs, it will query metrics for the past 5 minutes. This allows your metrics to stabilize and avoids reacting to transient spikes. 

 The instance limits are:  max 5 instances, min 1 instance. and the cool down setting is set to 5 minutes; the cool down setting is the amount of time to wait after a scale operation before scaling again. In this case, since the cooldown is 5 minutes and a scale operation just occurred, Autoscale will not attempt to scale again until after 5 minutes. This is to allow the metrics to stabilize first.

 These settings may not be valid for a real scenario, but are intentionally set (in conjunction with a small SKU for the app service plan) to easily reproduce the autoscale conditions.

 #### Deployment instructions


#### Run these commands by using the Azure CLI from your computer. You need to run az login to log in to Azure. Make sure that you have a subscription associated with your Azure Account If the CLI can open your default browser, it will do so and load an Azure sign-in page. Otherwise, open a browser page at https://aka.ms/devicelogin and enter the authorization code displayed in your terminal.
<br><br>
1 - Log in to Azure.
<br><br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;az login
<br><br>
2 - Deploy the ARM template provided by the sample, you will need to have a resource group already created.
<br><br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;az deployment group create --resource-group [your resource-group-name] --template-file .\deploymentTemplate\AppServiceAutoScale.json
<br><br>
3 - Once the deployment has successfully completed go to the Azure Portal, you will see three new resources created under the resource group.

4 - Find the App Service called "PerfStressWebApp",  go to overview.

5 - Click on "Get Publish Profile" option in the upper toolbar, that will download the publish profile to your computer.

6 - Open the solution in Visual Studio, right click on the project named "PerfStressWebApp", select "Publish".

7 - Select the option "New", then click on the "Import Profile" button located at the bottom of the dialog.

8 - Find and select the publish profile file that you downloaded in step 5.

9 - Click on "Publish", that will publish the PerfStress Web App to the App Service.

10 - Once the Web App has been successfully published, a browser's window will show up with the web application's home page.

11 - The UI is simple, by clicking the "trigger CPU Spike" button, a 100% CPU usage spike will happen for a period of time of one minute by default, or the number of minutes selected in the "minutes to run" text box (ten minutes is recommended to have a spike long enough to see the scaling effect). This is a fire and forget action.

12 - Go back to the Azure portal, select the App Service Plan (PerfStressWebAppPlan), in the overview, view you will see the CPU percentage chart.

13 - In 5 minutes the CPU spike will be reflected in the chart.

14 - Once you see the CPU spike, select the setting "Scale Out (App Service Plan)" on the settings Menu on the left.

15 - Select "Run History" in the upper toolbar.

16 - In the run history view, you will see the number of instances increased to two, also you will see the operation called "Autoscale scale up completed" in the autoscale events.

17 - Now you need to wait for the CPU spike to finish, and then after the cool period has passed (5 more minutes), the "Autoscale scale down" operation will appear in the list of autoscale events, and the number of instances will decrease to one again.

### Networking stress scenario

In this sample you create an Azure App Service plan which includes an Azure App Service. Then you deploy a basic Asp.Net Core MVC application that you can use to simulate a delayed HttpGet Action. The App Service plan is configured with a basic S1 SKU (1 core, 1.75 GB) to easily create the conditions for the autoscaling scenario. You can deploy the azure resources by publishing the Web Application, but it's recommended to use the provided ARM template since it has a set of custom autoscale rules.

To simulate the load and stress, you are going to use [the Apache JMeter™ application](https://jmeter.apache.org/). This tool is an open source software, designed to load test Web Applications among other test functions. You will use JMeter to simulate a heavy load on the App Service and analyze the response of the autoscaling engine and the configured rules. 

#### Autoscale rules

For this scenario, the App Service plan Scale-out custom setting is configured with the following rule combination:

Increase instances by 1 count when the sum of the HttpQueueLength metric > 8
Decrease instances by 1 count when the sum of the HttpQueueLength metric <= 4

The duration is set to 1 minute. This is amount of time that the Autoscale engine will look back for metrics. So in this case, 1 minute means that every time autoscale runs, it will query metrics for the past minute. The instance limits are:  max 5 instances, min 1 instance (for the deployed AppService Plan SKU you can set it up to 10 instances), and the cool down setting is set to 5 minutes; The cool down setting is the amount of time to wait after a scale operation before scaling again. In this case, since the cooldown is 5 minutes and a scale operation just occurred, Autoscale will not attempt to scale again until after 5 minutes. This is to allow the metrics to stabilize first. These settings may not be valid for a real scenario, but are intentionally set to easily reproduce the autoscale conditions.

#### HttpQueueLength metric explained

This metric represents the average number of HTTP requests that had to sit on the queue before being fulfilled. A high or increasing HTTP Queue length is a symptom of a plan under heavy load.

#### SocketOutboundTimeWait explained

The SocketOutboundTimeWait metric is another networking related metric available for in the App Service custom autoscaling configuration. This metric represents the number of TCP connections in TIME_WAIT state. The reason this metric can affect scalability is that one socket in a TCP connection that is shut down cleanly will stay in the TIME_WAIT state for period of 4 minutes. If many connections are being opened and closed quickly then socket's in TIME_WAIT may begin  to accumulate on a system. There are a finite number of socket connections that can be established at one time and one of the things that limits this number is the number of available local ports. If too many sockets are in TIME_WAIT you will find it difficult to establish new outbound connections and you will need to tune your App Service plan scale out settings and prevent the system reaching the limits.


#### Downloading and configuring JMeter

Download JMeter from [this link](https://downloads.apache.org//jmeter/binaries/apache-jmeter-5.3.zip) (Requires Java 8+), and install it in you computer. when installed, all you need to do is go the /Bin folder and find the JMeter windows batch file (JMeter.bat), as soon as you double click on the .bat file, a command prompt windows will popup; this is the command prompt through which JMeter will run. After a second the JMeter UI will popup, this UI is what you are going to use to create a Test Plan.

#### Creating a JMeter Test Plan

1) Creating a thread Group

    In the JMeter UI, by default, you will see an empty test plan. Right click on "TestPlan" on the left tree and select "Add", then "Threads", then "Thread Group". Enter a Name for the new thread group.
    For "Action to be taken after a sample error", select "Continue"

2) Thread properties

    Enter 700 or a higher number for "Number of Threads", this will simulate a number of users hitting your app service endpoint simultaneously.

    The ramp-up period tells JMeter how long to take to "ramp-up" to the full number of threads chosen, by default is set to 1 second.

    Loop count setting: you can select a high number of loops, or set it to infinite. If you choose "infinite" you can stop the run with the stop button in the UI.

    Same user on each iteration setting: When you select this checkbox the cookies that you get in the first response will be used for the following requests.

    Delay Thread Creation Until Needed: If this option is checked, the ramp-up delay and startup delay are performed before the thread data is created. If not checked, all the data required for the threads is created before starting the execution of a test
    
    Specify thread lifetime: Use this setting if you want to schedule and manage the thread's lifetime

3) Adding the HTTP sampler

    Right click on the Thread Group in the left tree, select "Add", then "Sampler", then "HTTP Request". Enter a name for the HTTP Request and some description in the comments box. 

    Provide the server name of the App Service you are going to load test, for this scenario, enter  "perfstresswebapp.azurewebsites.net" in the "Server Name or IP" box.

    Enter "/Values" in the Path box, that is the Path of you controller's action that simulates a web application having some delays. In this scenario there are no URL parameters but alternateviley you could add them to the parameters list below.

    Keep the other options default (Http Request should be GET)

4) Adding a View Results Window

    Right click on the HTTP Request added to the left tree and select "Add", then "Listener", then "View Results Tree" so once you run the load test it will show you the results in this window.  

5) Adding a Response Assertion

    You could also add a response assertion. Right click on the HTTP request on the left tree, select "Add", the "Assertions", then "Response Assertions". In this window you could, for example, add a 200 response assertion. Which will fail the entire test plan if any of the HTTP requests receive a response with a reponse code other than 200. Use the "Patterns to Test" section and click on the "Add" button, just enter 200 and add the row to the list.

5) Saving the Test Plan

    Save you test plan in your desired folder. The extension for JMeter is ".jmx". Your test plan is now ready to run.



#### Deployment instructions

*If you already ran the CPU stress scenario, you can skip steps 1-10 and go to step 11 directly.*

#### Run these commands by using the Azure CLI from your computer. You need to run az login to log in to Azure. Make sure that you have a subscription associated with your Azure Account If the CLI can open your default browser, it will do so and load an Azure sign-in page. Otherwise, open a browser page at https://aka.ms/devicelogin and enter the authorization code displayed in your terminal.
<br><br>
1 - Log in to Azure.
<br><br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;az login
<br><br>
2 - Deploy the ARM template provided by the sample, you will need to have a resource group already created.
<br><br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;az deployment group create --resource-group [your resource-group-name] --template-file .\deploymentTemplate\AppServiceAutoScale.json
<br><br>
3 - Once the deployment has successfully completed go to the Azure Portal, you will see three new resources created under the resource group.

4 - Find the App Service called "PerfStressWebApp",  go to overview.

5 - Click on "Get Publish Profile" option in the upper toolbar, that will download the publish profile to your computer.

6 - Open the solution in Visual Studio, right click on the project named "PerfStressWebApp", select "Publish".

7 - Select the option "New", then click on the "Import Profile" button located at the bottom of the dialog.

8 - Find and select the publish profile file that you downloaded in step 5.

9 - Click on "Publish", that will publish the PerfStress Web App to the App Service.

10 - Once the Web App has been successfully published, a browser's window will show up with the web application's home page.


#### Running the JMeter Test Plan

You have two ways of running the test plan, one option is to use the GUI, you have buttons for starting, stopping, clearing the results and monitoring you HTTP requests in the results view (you will see green successful requests or red failed ones). However it is best practice to use the CLI mode instead for better performance, leaving the GUI for Test creation and Test debugging.

For load testing using CLI Mode, use this command:

```Azure CLI
   jmeter -n -t [jmx file] -l [results file] -e -o [Path to web report folder]
```

So, in this case, you will find the test plan's run results on the results file.

Check the [JMeter Best Practices](https://jmeter.apache.org/usermanual/best-practices.html) for more information.


### Autoscale verification

 - After some time, the number of outbound sockets in wait time is going to increase, go back to the portal, find the App Service called "PerfStressWebApp" in you resource group, and select the setting "Scale Out (App Service Plan)" on the settings Menu on the left.

- Select "Run History" in the upper toolbar.

- In the run history view, verify if the number of instances have been increased to two, also you will see the operation called "Autoscale scale up completed" in the autoscale events.

- After the scale up operation has completed, continue watching the autoscale events, and then after the cool period has passed (5 more minutes), the "Autoscale scale down" operation will appear in the list of autoscale events, and the number of instances will decrease to one again.


To lear more about autoscaling, check the [Autoscale best practises](https://docs.microsoft.com/azure/azure-monitor/platform/autoscale-best-practices)