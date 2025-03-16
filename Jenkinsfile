pipeline {
    agent any
    
    environment {
        DOCKER_HUB_CREDS = credentials('docker-hub-credentials')
        DOCKER_IMAGE = "yourdockerhub/azure-vm-status-api"
        DOCKER_TAG = "${env.BUILD_NUMBER}"
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Parallel Tasks') {
            parallel {
                stage('Lint') {
                    steps {
                        sh '''
                            # Python linting
                            pip install flake8
                            flake8 app.py --count --select=E9,F63,F7,F82 --show-source --statistics
                            
                            # Dockerfile linting
                            docker run --rm -i hadolint/hadolint < Dockerfile
                        '''
                    }
                }
                
                stage('Security Scan') {
                    steps {
                        sh '''
                            # Python security scanning
                            pip install bandit
                            bandit -r app.py -f json -o bandit-results.json
                            
                            # Docker image scanning
                            docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .
                            docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy image ${DOCKER_IMAGE}:${DOCKER_TAG}
                        '''
                    }
                }
            }
        }
        
        stage('Build') {
            steps {
                sh '''
                    docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .
                    docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest
                '''
            }
        }
        
        stage('Push to Docker Hub') {
            steps {
                sh '''
                    echo ${DOCKER_HUB_CREDS_PSW} | docker login -u ${DOCKER_HUB_CREDS_USR} --password-stdin
                    docker push ${DOCKER_IMAGE}:${DOCKER_TAG}
                    docker push ${DOCKER_IMAGE}:latest
                '''
            }
        }
    }
    
    post {
        always {
            sh 'docker logout'
            cleanWs()
        }
    }
} 