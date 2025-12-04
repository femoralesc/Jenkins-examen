pipeline {
    agent any

    environment {
        PROJECT_NAME = "pipeline-test"
        SONARQUBE_URL = "http://sonarqube:9000"
        SONARQUBE_TOKEN = "sqa_bee897a6d9063e06f1e34bc7f9c89c57bcdfe678"
        TARGET_URL = "http://flaskapp:5000" // Cambia "flaskapp" por el nombre de tu contenedor Flask en jenkins-net
    }

    stages {

        stage('Install Python') {
            steps {
                sh '''
                    apt update
                    apt install -y python3 python3-venv python3-pip
                '''
            }
        }

        stage('Setup Environment') {
            steps {
                sh '''
                    python3 -m venv venv
                    . venv/bin/activate
                    pip install --upgrade pip
                    pip install -r requirements.txt
                '''
            }
        }

        stage('Python Security Audit') {
            steps {
                sh '''
                    . venv/bin/activate
                    pip install pip-audit
                    mkdir -p dependency-check-report
                    pip-audit -r requirements.txt -f markdown -o dependency-check-report/pip-audit.md || true
                '''
            }
        }

        stage('SonarQube Analysis') {
            steps {
                script {
                    def scannerHome = tool 'SonarQubeScanner'
                    withSonarQubeEnv('SonarQubeScanner') {
                        sh """
                            ${scannerHome}/bin/sonar-scanner \
                                -Dsonar.projectKey=$PROJECT_NAME \
                                -Dsonar.sources=. \
                                -Dsonar.host.url=$SONARQUBE_URL \
                                -Dsonar.login=$SONARQUBE_TOKEN
                        """
                    }
                }
            }
        }

        stage('Dependency Check') {
            environment {
                NVD_API_KEY = credentials('nvdApiKey')
            }
            steps {
                dependencyCheck additionalArguments: "--scan . --format HTML --out dependency-check-report --enableExperimental --enableRetired --nvdApiKey ${NVD_API_KEY} --disableOssIndex", odcInstallation: 'DependencyCheck'
            }
        }

        stage('OWASP ZAP Baseline Scan') {
            steps {
                sh '''
                    docker run --rm \
                    --network jenkins-net \
                    -v $WORKSPACE:/zap/wrk/:rw \
                    ghcr.io/zaproxy/zaproxy:stable \
                    zap-baseline.py -t ${TARGET_URL} -r ZAP-Baseline-Report.html
                '''
            }
        }

        stage('OWASP ZAP Full Scan') {
            steps {
                sh '''
                    docker run --rm \
                    --network jenkins-net \
                    -v $WORKSPACE:/zap/wrk/:rw \
                    ghcr.io/zaproxy/zaproxy:stable \
                    zap-full-scan.py -t ${TARGET_URL} -r ZAP-Full-Scan.html
                '''
            }
        }

        stage('Publish ZAP Reports') {
            steps {
                publishHTML([
                    allowMissing: true,
                    alwaysLinkToLastBuild: true,
                    keepAll: true,
                    reportDir: '.',                   
                    reportFiles: 'ZAP-Baseline-Report.html',  
                    reportName: 'OWASP ZAP Baseline Report'
                ])
                publishHTML([
                    allowMissing: true,
                    alwaysLinkToLastBuild: true,
                    keepAll: true,
                    reportDir: '.',                   
                    reportFiles: 'ZAP-Full-Scan.html',  
                    reportName: 'OWASP ZAP Full Scan Report'
                ])
            }
        }

        stage('Publish Dependency Check Report') {
            steps {
                publishHTML([
                    allowMissing: false,
                    alwaysLinkToLastBuild: true,
                    keepAll: true,
                    reportDir: 'dependency-check-report',
                    reportFiles: 'dependency-check-report.html',
                    reportName: 'OWASP Dependency Check Report'
                ])
            }
        }
    }
}

