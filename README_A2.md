# Assignment 2 - files to ADD to your repo (nothing in your code was changed)
Added: k8s/, deploy.sh, sonar-project.properties, .dockerignore, set_dockerhub_user.sh
Extended (only additions, no lines removed): Jenkinsfile, Jenkinsfile_Windows_Local, Jenkinsfile_Linux_VM
Untouched: app.py, test_app.py, Dockerfile, requirements.txt, templates, static, .gitignore, README.md

1. ./set_dockerhub_user.sh <dockerhub-username>   (or edit HUB_USER in the Jenkinsfile)
2. Jenkins: credential `dockerhub-creds` (Docker Hub user + access token), SonarQube server named `SonarQube`,
   and a SonarQube webhook to http://<jenkins>:8080/sonarqube-webhook/
3. Images are tagged with your APP_VERSION (V1, V3 ...). k8s manifests use V1 (old) and V3 (new): push both tags first.
4. minikube start --driver=docker; minikube addons enable ingress; ./deploy.sh rolling|bluegreen|canary|abshadow
5. See which version answers (V1 has /api/v1.0, V3 does not):
   for i in $(seq 20); do curl -s -o /dev/null -w "%{http_code}\n" <url>/api/v1.0; done | sort | uniq -c
