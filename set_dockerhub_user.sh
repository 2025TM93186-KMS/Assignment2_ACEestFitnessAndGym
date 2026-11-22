#!/usr/bin/env bash
# Usage: ./set_dockerhub_user.sh <your-dockerhub-username>
grep -rl DOCKERHUB_USER Jenkinsfile* k8s | xargs sed -i "s/DOCKERHUB_USER/$1/g"
echo "Done: images now point to $1/aceest-fitness"
