@Library('my-shared-library') _

pipeline {
    agent {
        docker {
            // Use the most stable official image
            image 'maven:3.9.6-eclipse-temurin-17' 
            args '-v /var/run/docker.sock:/var/run/docker.sock -u root'
        }
    }

    options {
        // Prevents the "Permission Denied" errors during checkout
        skipDefaultCheckout(true)
    }

    environment {
        APP_NAME = "register-app-pipeline"
        RELEASE = "1.0.0"
        IMAGE_TAG = "${RELEASE}-${BUILD_NUMBER}"
        SLACK_CHANNEL = '#test-notify'
    }

    stages {
        stage('Cleanup & Checkout') {
            steps {
                deleteDir() // Clean workspace as root to avoid permission errors
                checkout scm
                script {
                    // Install only the CLI client, which is faster and more stable
                    sh 'apt-get update && apt-get install -y docker.io'
                    notify("Environment Ready") 
                }
            }
        }

        stage("Build Application") {
            steps {
                // Since you have a pom.xml at the root, this will build your project
                sh 'mvn clean package -DskipTests'
            }
        }

        stage("Build & Push Docker Image") {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', passwordVariable: 'DOCKER_PASS', usernameVariable: 'DOCKER_USER')]) {
                        def fullImage = "${DOCKER_USER}/${APP_NAME}:${IMAGE_TAG}"
                        
                        sh "echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin"
                        sh "docker build -t ${fullImage} ."
                        sh "docker push ${fullImage}"
                        sh "docker logout"
                        
                        notify("Build #${env.BUILD_NUMBER} Pushed to Hub")
                    }
                }
            }
        }
    }

    post {
        success {
            slackSend(channel: "${SLACK_CHANNEL}", color: "good", 
                message: "*BUILD SUCCESS* \nJob: ${env.JOB_NAME} \nBuild: #${env.BUILD_NUMBER}")
        }
        failure {
            slackSend(channel: "${SLACK_CHANNEL}", color: "danger", 
                message: "*BUILD FAILED* \nJob: ${env.JOB_NAME} \nBuild: #${env.BUILD_NUMBER}")
        }
    }
}