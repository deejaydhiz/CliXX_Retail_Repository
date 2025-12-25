pipeline {
  agent any
  tools {
    jdk 'Java-11' 
  }
  environment {
    VERSION = "1.0.${BUILD_NUMBER}"
    PATH = "${PATH}:${getSonarPath()}"
  }

  stages {
    stage ('Sonarcube Scan') {
      steps {
        script {
          scannerHome = tool 'sonarqube_v4.7'
        }
        // use the withCredentials() Jenkins function to introduce the SONAR_TOKEN secret 
        withCredentials([string(credentialsId: 'SONAR_TOKEN', variable: 'SONAR_TOKEN')]){
          withSonarQubeEnv('SonarQubeScanner') {
            sh " ${scannerHome}/bin/sonar-scanner \
              -Dsonar.projectKey=CliXX-App-Deji \
              -Dsonar.login=${SONAR_TOKEN} "
          }
        }
      }
    }

    stage('Quality Gate') {
      steps {
        timeout(time: 3, unit: 'MINUTES') {
          waitForQualityGate abortPipeline: true
        }
      }
    }

    stage ('Build Docker Image') {
      steps {
        // script{
        //   dockerHome= tool 'docker-inst'
        // }
        //  sh "${dockerHome}/bin/docker build . -t clixx-image:$VERSION "
        sh "docker build . -t clixx-image:$VERSION "
      }
    }

    stage ('Starting Docker Image') {
      steps {
        sh '''
          if ( docker ps|grep clixx-cont ) then
            echo "Docker image exists, killing it"
            docker stop clixx-cont
            docker rm clixx-cont
            docker run --name clixx-cont  -p 80:80 -d clixx-image:$VERSION
          else
            docker run --name clixx-cont  -p 80:80 -d clixx-image:$VERSION
          fi
        '''
      }
    }
  }
}

// define a function that references the tool 
def getSonarPath(){
  def SonarHome= tool name: 'sonarqube_v4.7', type: 'hudson.plugins.sonar.SonarRunnerInstallation'
  return SonarHome
}

def getDockerPath(){
  def DockerHome= tool name: 'docker-inst', type: 'dockerTool'
  return DockerHome
}


