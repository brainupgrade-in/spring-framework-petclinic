pipeline {
    agent {
        label 'jenkins-k8s-agent'
    }
    options {
      disableConcurrentBuilds()
      buildDiscarder(logRotator(numToKeepStr: '5'))
    }

    environment {
        SCANNER_HOME=tool 'sonarqube'
    }

    stages {
        stage('Compile') {
            steps {
                // git url: 'https://github.com/brainupgrade-in/spring-framework-petclinic.git', branch: 'main'
                container('maven') {
                  sh 'mvn -B -ntp clean compile'
                }
            }
        }
        stage('JUnit Tests') {
            steps {
                container('maven') {
                    sh 'mvn test '
                    junit 'target/surefire-reports/**/*.xml'
                }
            }
        }        
        stage('Code Coverage') {
            steps {
                container('maven') {
                    jacoco(
                        execPattern: '**/build/jacoco/*.exec',
                        classPattern: '**/build/classes/java/main',
                        sourcePattern: '**/src/main'
                    )
                }
            }
        }        
        stage('Performance Tests') {
            steps {
                container('docker'){
                    sh "wget https://raw.githubusercontent.com/brainupgrade-in/jenkins/main/src/test/resources/jmeter-e2e.jmx"
                    sh "mkdir -p src/test/resources && mv jmeter-e2e.jmx src/test/resources/jmeter-e2e.jmx"
                }
                container('jmeter'){
                    sh "ls && ls src/test/resources"
                    sh "jmeter -n -t ${env.WORKSPACE}/src/test/resources/jmeter-e2e.jmx -l result.jtl -e -o result"
                    perfReport filterRegex: '', sourceDataFiles: '**/*.jtl'
                    publishHTML([allowMissing: false, alwaysLinkToLastBuild: false, keepAll: false, reportDir: 'result', reportFiles: 'index.html', reportName: 'JMeter-Report', reportTitles: ''])
                }
            }
        }        
        stage('Build') {
            steps {
                container('maven') {
                  sh 'mvn install'
                }
            }
        }
        stage("Sonarqube Analysis "){
            steps{
                withSonarQubeEnv('sonarqube') {
                    sh ''' $SCANNER_HOME/bin/sonar-scanner -Dsonar.projectName=Petclinic \
                    -Dsonar.java.binaries=. \
                    -Dsonar.projectKey=Petclinic '''
    
                }
            }
        }
        
        // stage("OWASP Dependency Check"){
        //     steps{
        //         dependencyCheck additionalArguments: '--scan ./ --format HTML ', odcInstallation: 'owasp-dc'
        //         dependencyCheckPublisher pattern: '**/dependency-check-report.html'
        //     }
        // }

        stage("Docker Build & Push"){
            steps{
                container('docker') {
                    withDockerRegistry(credentialsId: 'docker-hub-credentials', url: 'https://index.docker.io/v1/') {                        
                        sh "docker build -t brainupgrade/spring-framework-petclinic:${env.BUILD_ID} ."
                        sh "docker push brainupgrade/spring-framework-petclinic:${env.BUILD_ID} "
                    }
                }
            }
        }        
        stage('Image Scan'){
            steps{
                script{
                    container('docker'){
                        sh "wget https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/html.tpl"
                    }
                    container('trivy'){
                        sh "trivy image --severity HIGH,CRITICAL --format template --template '@html.tpl'   --output image-cve.html brainupgrade/spring-framework-petclinic:${env.BUILD_ID}"
                        publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, keepAll: true, reportDir: '.', reportFiles: 'image-cve.html', reportName: 'ImageScan-CVE-Trivy-Report', reportTitles: 'Trivy Image Scan'])
                        sh "trivy image --quiet --vuln-type os,library --exit-code 1 --severity CRITICAL brainupgrade/spring-framework-petclinic:${env.BUILD_ID}"
                    }
                }
            }
        }        
    }
}
