pipeline {
    agent any
    triggers {
        pollSCM('H/2 * * * *')
    }

    environment {
        APP_NAME     = 'aceest-fitness-app'
        APP_VERSION  = 'V1'
        TAG          = "${APP_VERSION}-${BUILD_NUMBER}"
        HUB_USER     = 'devkg1'
        K8S_NS       = 'aceest'

        DEV_URL      = "http://localhost:5001"
        TEST_URL     = "http://localhost:5002"
        STAGE_URL    = "http://localhost:5003"
        PROD_URL     = "http://localhost:5004"

        CURRENT_PORT = "${env.BRANCH_NAME == 'Develop' ? '5001' : env.BRANCH_NAME == 'Test' ? '5002' : env.BRANCH_NAME == 'Stage' ? '5003' : '5004'}"
    }

    stages {
        stage('Initialize') {
            steps {
                echo "Starting the automation pipeline for: ${env.APP_NAME} v${env.APP_VERSION}"
            }
        }

        stage('Repository Synchronization') {
            steps {
                echo 'Pulling application code parameters cleanly from GitHub tracking layers...'
                checkout scm
            }
        }

        stage('Docker Compression Assembly') {
            steps {
                echo 'Assembling cached container virtualization blocks on Docker Engine...'
                bat "docker build -t ${APP_NAME}:${APP_VERSION}-${BUILD_NUMBER} ."
            }
        }

        stage('Static Lint Analysis') {
            steps {
                echo 'Validating Python syntax compilation structure inside the Docker Container...'
                bat "docker run --rm ${APP_NAME}:${APP_VERSION}-${BUILD_NUMBER} python -m py_compile app.py"
            }
        }

        stage('Automated Pytest Execution') {
            steps {
                echo 'Invoking component assertion tests inside clean container context...'
                bat "docker run --rm ${APP_NAME}:${APP_VERSION}-${BUILD_NUMBER} pytest test_app.py"
            }
        }

        stage('Coverage Report') {
            steps {
                echo 'Generating coverage report for SonarQube...'
                bat """
                    docker rm -f aceest-cov-${BUILD_NUMBER} 2>nul
                    docker run --name aceest-cov-${BUILD_NUMBER} ${APP_NAME}:${APP_VERSION}-${BUILD_NUMBER} sh -c "pip install -q pytest-cov && pytest -q --cov=app --cov-report=xml:coverage.xml test_app.py"
                    set RC=%ERRORLEVEL%
                    docker cp aceest-cov-${BUILD_NUMBER}:/app/coverage.xml .
                    docker rm -f aceest-cov-${BUILD_NUMBER}
                    exit /b %RC%
                """
            }
        }

        stage('SonarQube Analysis') {
            steps {
                echo 'Running static code analysis on SonarQube...'
                script {
                    def scannerHome = tool 'SonarScanner'
                    withSonarQubeEnv('SonarQube') {
                        bat "\"${scannerHome}\\bin\\sonar-scanner.bat\" -Dsonar.projectVersion=${APP_VERSION}"
                    }
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Push to Docker Hub') {
            when { branch 'main' }
            steps {
                echo "Pushing ${HUB_USER}/aceest-fitness:${APP_VERSION} to Docker Hub..."
                withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'U', passwordVariable: 'P')]) {
                    bat 'echo %P%| docker login -u %U% --password-stdin'
                }
                bat """
                    docker tag ${APP_NAME}:${APP_VERSION}-${BUILD_NUMBER} ${HUB_USER}/aceest-fitness:${APP_VERSION}-${BUILD_NUMBER}
                    docker tag ${APP_NAME}:${APP_VERSION}-${BUILD_NUMBER} ${HUB_USER}/aceest-fitness:${APP_VERSION}
                    docker push ${HUB_USER}/aceest-fitness:${APP_VERSION}-${BUILD_NUMBER}
                    docker push ${HUB_USER}/aceest-fitness:${APP_VERSION}
                """
            }
        }

        stage('Deploy to Dev') {
            when { branch 'Develop' }
            steps {
                echo "Deploying to DEV environment at ${env.DEV_URL}..."
                powershell """
                    \$containers = docker ps -q --filter "publish=${CURRENT_PORT}"
                    if (\$containers) { docker stop \$containers }
                    docker run -d -p ${CURRENT_PORT}:${CURRENT_PORT} --name ${APP_NAME}-dev-${BUILD_NUMBER} ${APP_NAME}:${APP_VERSION}-${BUILD_NUMBER} python app.py --port=${CURRENT_PORT}
                """
            }
        }

        stage('Deploy to Test') {
            when { branch 'Test' }
            steps {
                echo "Deploying to TEST environment at ${env.TEST_URL}..."
                powershell """
                    \$containers = docker ps -q --filter "publish=${CURRENT_PORT}"
                    if (\$containers) { docker stop \$containers }
                    docker run -d -p ${CURRENT_PORT}:${CURRENT_PORT} --name ${APP_NAME}-test-${BUILD_NUMBER} ${APP_NAME}:${APP_VERSION}-${BUILD_NUMBER} python app.py --port=${CURRENT_PORT}
                """
            }
        }

        stage('Deploy to Stage') {
            when { branch 'Stage' }
            steps {
                echo "Deploying to STAGING environment at ${env.STAGE_URL}..."
                powershell """
                    \$containers = docker ps -q --filter "publish=${CURRENT_PORT}"
                    if (\$containers) { docker stop \$containers }
                    docker run -d -p ${CURRENT_PORT}:${CURRENT_PORT} --name ${APP_NAME}-stage-${BUILD_NUMBER} ${APP_NAME}:${APP_VERSION}-${BUILD_NUMBER} python app.py --port=${CURRENT_PORT}
                """
            }
        }

        stage('Deploy to Prod') {
            when { branch 'main' }
            steps {
                echo "Deploying to PRODUCTION environment at ${env.PROD_URL}..."
                powershell """
                    \$containers = docker ps -q --filter "publish=${CURRENT_PORT}"
                    if (\$containers) { docker stop \$containers }
                    docker run -d -p ${CURRENT_PORT}:${CURRENT_PORT} --name ${APP_NAME}-prod-${BUILD_NUMBER} ${APP_NAME}:${APP_VERSION}-${BUILD_NUMBER} python app.py --port=${CURRENT_PORT}
                """
            }
        }

        stage('Deploy to Kubernetes (Rolling Update)') {
            when { branch 'main' }
            steps {
                echo 'Rolling update on Kubernetes...'
                bat """
                    kubectl apply -f k8s/namespace.yaml -f k8s/rolling.yaml
                    kubectl -n ${K8S_NS} set image deployment/aceest-rolling app=${HUB_USER}/aceest-fitness:${APP_VERSION}-${BUILD_NUMBER}
                    kubectl -n ${K8S_NS} rollout status deployment/aceest-rolling --timeout=120s
                """
            }
        }
    }

    post {
        always {
            echo 'Cleaning the Jenkins workspace.'
            cleanWs()
        }
        success {
            echo 'I succeeded!'
        }
        unstable {
            echo 'I am unstable :/'
        }
        failure {
            echo 'I failed :('
            script {
                if (env.BRANCH_NAME == 'main') {
                    echo 'Rolling back Kubernetes deployment to the last stable revision...'
                    bat "kubectl -n ${K8S_NS} rollout undo deployment/aceest-rolling || exit /b 0"
                }
                try {
                    if (env.NOTIFICATION_EMAIL) {
                        mail to: "${env.NOTIFICATION_EMAIL}",
                             subject: "Failed Pipeline: ${currentBuild.fullDisplayName}",
                             body: "Something is wrong with ${env.BUILD_URL}"
                    } else {
                        echo "No NOTIFICATION_EMAIL environment variable set. Skipping email dispatch."
                    }
                } catch (Exception mailError) {
                    echo "Unable to dispatch SMTP alert notification: ${mailError.getMessage()}"
                }
            }
        }
    }
}