# jenui2024
Technical Debt Contest implementation

Configure a webhook at your sonarqube server (admin user is necessary). 

Add the webhook at menu Administration > Configuration > Webhooks or directly at:
https://your.sonarqube.url/admin/webhooks # our sonarqube server is installed on inf.uva.es premises and configured to identify all students as users 
Webhook:
http://user:password@your.leaderboard.url:8080/sonarqubewebhook # our leaderboard url is based in tablon

Define a service at your.leaderboard.url server that requires user and password authorization.

We implements the service with Flask (using flask_restful).
Our service runs an R script previously prepared at tested for empirical studies 

The R script obtains metrics from the project submitted to the sonarqube server (the one who initiate the service through the webhook).
It adds the basic and derived metrics obtained to a data file and call the leaderboard tool (tablon) with this file in pipeline.

This repo contains the basic of the Flask service and the R script.
