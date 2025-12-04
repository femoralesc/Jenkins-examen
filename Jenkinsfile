pipeline {
    agent any

    environment {
        PROJECT_NAME = "pipeline-test"
        SONARQUBE_URL = "http://sonarqube:9000"
        SONARQUBE_TOKEN = "sqa_bee897a6d9063e06f1e34bc7f9c89c57bcdfe678"
        TARGET_URL = "http://flaskapp:5000" // Contenedor Flask
        ZAP_HOST = "zap"
        ZAP_PORT = "8080"
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

        stage('OWASP ZAP Baseline Scan via API') {
            steps {
                script {
                    sh """
                        echo 'Esperando a que ZAP esté listo...'
                        until curl -s "http://${ZAP_HOST}:${ZAP_PORT}/JSON/core/view/version/" | grep -q version; do
                            echo 'ZAP aún no listo, esperando 5s...'
                            sleep 5
                        done
                        echo 'ZAP listo para escanear'

                        echo 'Abriendo URL de la app en ZAP'
                        curl -s "http://${ZAP_HOST}:${ZAP_PORT}/JSON/core/action/accessUrl/?url=${TARGET_URL}"

                        echo 'Ejecutando Spider'
                        curl -s "http://${ZAP_HOST}:${ZAP_PORT}/JSON/spider/action/scan/?url=${TARGET_URL}"

                        echo 'Ejecutando Active Scan'
                        curl -s "http://${ZAP_HOST}:${ZAP_PORT}/JSON/ascan/action/scan/?url=${TARGET_URL}"

                        echo 'Generando reporte HTML'
                        curl -s "http://${ZAP_HOST}:${ZAP_PORT}/OTHER/core/other/htmlreport/?apikey=&out=ZAP-Baseline-Report.html"
                    """
                }
            }
        }

        stage('Publish ZAP Report') {
            steps {
                publishHTML([
                    allowMissing: true,
                    alwaysLinkToLastBuild: true,
                    keepAll: true,
                    reportDir: '.',                   
                    reportFiles: 'ZAP-Baseline-Report.html',  
                    reportName: 'OWASP ZAP Report'
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
                    reportFiles: 'pip-audit.md',
                    reportName: 'Python Dependency Check Report'
                ])
            }
        }
    }
}


