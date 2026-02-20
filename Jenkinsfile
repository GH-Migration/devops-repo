pipeline {
    agent any
    
    tools {
        jdk 'Java17'
        maven 'Maven3'
    }

    environment {
        APP_NAME = "register-app-pipeline"
        RELEASE = "1.0.0"
        // This helper automatically creates DOCKER_CREDENTIALS_USR and DOCKER_CREDENTIALS_PSW
        DOCKER_CREDENTIALS = credentials("dockerhub-creds")
        IMAGE_NAME = "${DOCKER_CREDENTIALS_USR}/${APP_NAME}"
        IMAGE_TAG = "${RELEASE}-${BUILD_NUMBER}"
        SONAR_TOKEN = credentials('sonarcloud-token')
    }

    stages {
        stage("Cleanup Workspace") {
            steps {
                cleanWs()
            }
        }

        stage("Checkout from SCM") {
            steps {
                git branch: 'main', credentialsId: 'Org', url: 'https://github.com/Samarth-DevTools/register-app.git'
            }
        }

        stage('Verify Environment') {
            steps {
                sh 'java -version'
                sh 'mvn -version'
            }
        }

        stage("Build Application") {
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }

        stage("Verify Compilation") {
            steps {
                sh '''
                    echo "Listing compiled class files in target/classes:"
                    find target/classes -name "*.class" || echo "No .class files found!"
                '''
            }
        }

        stage("SonarQube Analysis") {
            steps {
                sh '''
                    sonar-scanner \
                    -Dsonar.projectKey=game-app_ga-1 \
                    -Dsonar.organization=game-app \
                    -Dsonar.token=$SONAR_TOKEN \
                    -Dsonar.sources=. \
                    -Dsonar.host.url=https://sonarcloud.io
                '''
            }
        }

        stage("Build & Push Docker Image") {
            steps {
                script {
                    // Uses the Docker Pipeline plugin logic
                    docker.withRegistry('', 'dockerhub-creds') {
                        def docker_image = docker.build("${IMAGE_NAME}:${IMAGE_TAG}")
                        docker_image.push()
                        docker_image.push("latest")
                    }
                }
            }
        }

        stage("Trivy Vulnerability Scan") {
            steps {
                // Scanning the image we just built
                sh """
                    docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
                    aquasec/trivy image ${IMAGE_NAME}:${IMAGE_TAG} \
                    --severity HIGH,CRITICAL --format table
                """
            }
        }

        stage("Deploy for DAST") {
            steps {
                script {
                    // Remove old container if it exists, then run new one
                    sh "docker rm -f test-app || true"
                    sh "docker run -d -p 8082:8080 --name test-app ${IMAGE_NAME}:${IMAGE_TAG}"
                    echo "Waiting for application to stabilize..."
                    sleep 15 
                }
            }
        }

        stage("DAST - Security Scan") {
            steps {
                // Run OWASP ZAP baseline scan against the container running on port 8082
                sh """
                    docker run --rm --network="host" owasp/zap2docker-stable zap-baseline.py \
                    -t http://localhost:8082 -r zap-report.html || true
                """
            }
            post {
                always {
                    archiveArtifacts artifacts: 'zap-report.html', fingerprint: true
                    sh "docker rm -f test-app || true"
                }
            }
        }
    }
}
