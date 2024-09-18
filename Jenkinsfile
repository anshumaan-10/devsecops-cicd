pipeline {
    agent any

    stages {
        stage('Build Artifact') {
            steps {
                // Build the artifact but skip tests
                sh "mvn clean package -DskipTests=true"
                // Archive the JAR file
                archiveArtifacts artifacts: 'target/*.jar', allowEmptyArchive: true
            }
        }
        stage('Unit Test') {
            steps {
                // Run the unit tests
                sh "mvn test"
            }
            post {
                always {
                    // Archive the test reports
                    junit '**/target/surefire-reports/*.xml'
                }
                success {
                    echo "Unit tests passed"
                }
                failure {
                    echo "Unit tests failed"
                }
            }
        }
        stage('Code Coverage') {
            steps {
                // Run JaCoCo to generate the coverage report
                sh 'mvn jacoco:prepare-agent test jacoco:report'
            }
            post {
                always {
                    // Archive the JaCoCo code coverage report
                    jacoco execPattern: '**/target/jacoco.exec',
                           classPattern: '**/target/classes',
                           sourcePattern: '**/src/main/java',
                           inclusionPattern: '**/*.class',
                           exclusionPattern: '**/*Test.class'
                }
            }
        }
    }
    
    post {
        always {
            // Additional post actions if needed
            archiveArtifacts artifacts: 'target/site/jacoco/**', allowEmptyArchive: true
        }
    }
}
