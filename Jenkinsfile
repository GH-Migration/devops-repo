@Library('my-shared-library') _

pipeline {
    agent any 

    environment {
        APP_NAME = "register-app-pipeline"
        RELEASE = "1.0.0"
        IMAGE_TAG = "${RELEASE}-${BUILD_NUMBER}"
        SLACK_CHANNEL = '#test-notify' // Ensure your bot is invited to this channel
    }

    stages {
        stage('Checkout & Clean') {
            steps {
                cleanWs()
                checkout scm
                notify("Started Build #${env.BUILD_NUMBER}") // Shared Library call
            }
        }

        stage('Build & Test') {
            steps {
                // This builds the JAR and runs Unit Tests
                sh 'mvn clean package'
                notify("Maven Build & Test Successful")
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    // Pulling Docker Hub username from credentials to build the tag
                    withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', passwordVariable: 'DOCKER_PASS', usernameVariable: 'DOCKER_USER')]) {
                        sh "docker build -t ${DOCKER_USER}/${APP_NAME}:${IMAGE_TAG} ."
                        sh "docker tag ${DOCKER_USER}/${APP_NAME}:${IMAGE_TAG} ${DOCKER_USER}/${APP_NAME}:latest"
                    }
                }
            }
        }

        stage('Trivy Security Scan') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', passwordVariable: 'DOCKER_PASS', usernameVariable: 'DOCKER_USER')]) {
                        // Scan the image we just built before pushing it
                        sh "docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
                            aquasec/trivy image ${DOCKER_USER}/${APP_NAME}:${IMAGE_TAG} \
                            --severity HIGH,CRITICAL --format table"
                    }
                }
            }
        }

        stage('Push to Docker Hub') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', passwordVariable: 'DOCKER_PASS', usernameVariable: 'DOCKER_USER')]) {
                        sh "echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin"
                        sh "docker push ${DOCKER_USER}/${APP_NAME}:${IMAGE_TAG}"
                        sh "docker push ${DOCKER_USER}/${APP_NAME}:latest"
                        sh "docker logout"
                    }
                }
            }
        }
    }

    post {
        success {
            slackSend(
                channel: "${SLACK_CHANNEL}",
                color: "good",
                message: "*BUILD SUCCESSFUL*\n*Job:* ${env.JOB_NAME}\n*Build:* #${env.BUILD_NUMBER}\n*Image:* ${APP_NAME}:${IMAGE_TAG}\n*URL:* ${env.BUILD_URL}"
            )
        }
        failure {
            slackSend(
                channel: "${SLACK_CHANNEL}",
                color: "danger",
                message: "*BUILD FAILED*\n*Job:* ${env.JOB_NAME}\n*Build:* #${env.BUILD_NUMBER}\n*Check Logs:* ${env.BUILD_URL}console"
            )
        }
    }
}