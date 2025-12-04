pipeline {
    agent any

    environment {
        PROJECT_NAME = "pipeline-test"
        SONARQUBE_URL = "http://sonarqube:9000"
        SONARQUBE_TOKEN = "sqa_bee897a6d9063e06f1e34bc7f9c89c57bcdfe678"
        TARGET_URL = "http://flaskapp:5000" // Contenedor Flask
        ZAP_HOST = "zap"                    // Contenedor ZAP
        ZAP_PORT = "8080"
    }

    stages {

        stage('Install Python & Setup venv') {
            steps {
                sh '''
                    apt update
                    apt install -y python3 python3-venv python3-pip
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

        stage('Install ZAP CLI') {
            steps {
                sh '''
                    . venv/bin/activate
                    pip install zap-cli
                '''
            }
        }

        stage('OWASP ZAP Baseline Scan') {
            steps {
                script {
                    sh """
                        # Esperar a que ZAP esté listo
                        zap-cli --zap-url http://${ZAP_HOST}:${ZAP_PORT} status -t 120
                        
                        # Abrir la URL de la app Flask
                        zap-cli --zap-url http://${ZAP_HOST}:${ZAP_PORT} open-url ${TARGET_URL}
                        
                        # Spider y active scan
                        zap-cli --zap-url http://${ZAP_HOST}:${ZAP_PORT} spider ${TARGET_URL}
                        zap-cli --zap-url http://${ZAP_HOST}:${ZAP_PORT} active-scan ${TARGET_URL}
                        
                        # Generar reporte HTML
                        zap-cli --zap-url http://${ZAP_HOST}:${ZAP_PORT} report -o ZAP-Baseline-Report.html -f html
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


