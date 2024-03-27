# Technical Debt Contest implementation

This image represents the contest environment and phases:
https://github.com/yania/jenui2024/blob/main/ContestEnvironment_v3.png

Configure a webhook at your sonarqube server (admin user is necessary). 
Add the new webhook at menu Administration > Configuration > Webhooks or directly at:
https://your.sonarqube.url/admin/webhooks # our sonarqube server is installed on inf.uva.es premises and configured to identify all students as users 

The webhook:
http://user:password@your.leaderboard.url:8080/sonarqubewebhook # our leaderboard url is based in tablon

Set the user and password of your service in the url of the webhook

Define a service at your.leaderboard.url server that requires user and password authorization.

We implements the service with Flask (using flask_restful). See mysonarqubewebhook.py in this repo.

Our service runs an R script previously prepared, tested and used for software engineering empirical studies:
* https://2021.techdebtconf.org/details/techdebt-2021-technical-papers/4/Carrot-and-Stick-approaches-revisited-when-managing-Technical-Debt-in-an-educational-
* https://doi.org/10.1016/j.infsof.2022.106946

The R script (see contest.R in this repo) obtains metrics from the project submitted to the sonarqube server (the one who initiate the service through the webhook).
The script adds the measures obtained from sonarqube and the derived metrics calculated from that measures to a data file and call the leaderboard tool (tablon) with this file in pipeline. The script named submit2leaderboard.sh communicate with tablon during the contests.
This means at the end of the contest we have in tablon two different leaderboards, the one obtained during the contest and the final, manually checked by the instructors. We close the first leaderboard, remove the webhook and open the other (See submit2checkedleaderboard.sh in this repo) to submit the sonarqube analysis just of the teams that instructors checked.

This repo contains the basic of the Flask service and the R script, the shell scripts that submit data to leaderboards.
