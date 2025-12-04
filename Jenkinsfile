pipeline {
    agent any

    environment {
        PROJECT_NAME = "pipeline-test"
        SONARQUBE_URL = "http://sonarqube:9000"
        SONARQUBE_TOKEN = "sqa_d1cae587e88c02f425c8ca6a1559612afb182877"
    }

    stages {

        stage('Install Python & Setup venv') {
            steps {
                sh '''
                    apt update
                    apt install -y python3 python3-venv python3-pip curl
                    python3 -m venv venv
                    . venv/bin/activate
                    pip install --upgrade pip
                    pip install -r requirements.txt
                '''
            }
        }

        stage('Python Dependency Audit (pip-audit)') {
            steps {
                sh '''
                    . venv/bin/activate
                    pip install pip-audit
                    mkdir -p dependency-check-report
                    pip-audit -r requirements.txt -f markdown -o dependency-check-report/pip-audit.md || true
                '''
            }
        }

        /*
         * 🔥 SONARQUBE STATIC ANALYSIS
         * Analiza SOLO código Python (.py)
         * Busca vulnerabilidades directamente en vulnerable_flask_app.py
         * Usa el archivo sonar-project.properties
         */
        stage('SonarQube Static Code Analysis') {
            steps {
                script {
                    def scannerHome = tool 'SonarQubeScanner'

                    withSonarQubeEnv('SonarQubeScanner') {
                        sh """
                            ${scannerHome}/bin/sonar-scanner \
                                -Dsonar.host.url=$SONARQUBE_URL \
                                -Dsonar.login=$SONARQUBE_TOKEN
                        """
                    }
                }
            }
        }

        stage('Publish pip-audit Report') {
            steps {
                publishHTML([
                    allowMissing: false,
                    alwaysLinkToLastBuild: true,
                    keepAll: true,
                    reportDir: 'dependency-check-report',
                    reportFiles: 'pip-audit.md',
                    reportName: 'Python Dependency Vulnerabilities'
                ])
            }
        }
    }
}

