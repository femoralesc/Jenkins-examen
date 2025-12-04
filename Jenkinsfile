pipeline {
    agent any

    environment {
        PROJECT_NAME = "pipeline-test"
        SONARQUBE_URL = "http://sonarqube:9000"
        SONARQUBE_TOKEN = "sqa_d1cae587e88c02f425c8ca6a1559612afb182877"
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

        stage('OWASP ZAP Scan via Plugin') {
            steps {
                script {
                    echo 'Iniciando ZAP...'
                    startZap(
                        zapHome: '/usr/share/zaproxy', 
                        daemon: true, 
                        host: '0.0.0.0', 
                        port: '8080'
                    )

                    echo 'Ejecutando Spider con ZAP...'
                    runZapCrawler(
                        target: "${TARGET_URL}",
                        contextName: 'Default Context'
                    )

                    echo 'Ejecutando Active Scan con ZAP...'
                    runZapAttack(
                        target: "${TARGET_URL}",
                        contextName: 'Default Context'
                    )

                    echo 'Archiving ZAP Report...'
                    archiveZap(
                        zapReportFile: 'ZAP-Baseline-Report.html',
                        reportType: 'HTML'
                    )

                    stopZap()
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

