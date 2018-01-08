Base Image:
Requires oci8, zip files are downloaded from Oracel as "freelancer" Wen, also copy available in "repo" now.
>cd $REPO_ROOT
>docker build -f Base_Dockerfile .
(read thro Base_Dockerfile first before you build new base image)



Dashing Image:
put your custermized dashing config under "dashing" and "jobs"
build your docker container by doing:
>cd $REPO_ROOT
>docker build --build-arg project=[wen|sensu|balabala] .


since the limitation of build, the missing files in the each path would mark as failure, thats why there are "empty.txt" files in the sub folders


How to deploy
>docker run -d --publish 8081:3030 dockerregistery.mycompany.com:18444/dashing/wen:<version>

How to Test
>curl -L localhost:8081/your_endpoint


###############simple dashing concept########################
dashboards:
  *.erb files
widget_name:
  different folders for each widget_name, under each has scss html and some coffee
jobs:
  *.rb

In *.erb
 data-view="widget_name"  (Capital first letter)
 data-id="whatever_you_want_it_be_called" 

In *.rb
 send_event("whatever_you_want_it_be_called", some paras)

by default dashing use 3030 port

by default, i dont know where the log is..... dont trust --help

