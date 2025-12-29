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
    stage ('SonarQube Scan') {
      steps {
        script {
          scannerHome = tool 'sonarqube_v4.7'
        }
        withCredentials([string(credentialsId: 'SONAR_TOKEN', variable: 'SONAR_TOKEN')]){
          withSonarQubeEnv('SonarQubeScanner') {
            sh """
              ${scannerHome}/bin/sonar-scanner \
              -Dsonar.projectKey=CliXX-App-Deji \
              -Dsonar.login='%SONAR_TOKEN%' \
              -Dsonar.projectVersion=${VERSION} \
              -Dsonar.exclusions="wp-content/**/*,wp-includes/**/*,wp-admin/**/*,wordpress/**/*"
            """
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
          if ( docker ps -a | grep clixx-cont ) then
            echo "Docker image exists, killing it"
            docker stop clixx-cont
            docker rm clixx-cont
            docker run --name clixx-cont -p 80:80 -d clixx-image:$VERSION
          else
            docker run --name clixx-cont -p 80:80 -d clixx-image:$VERSION
          fi
        '''
      }
    }
    
    stage ('Restore CliXX Database') {
      steps {
        sh '''
        python3 -m venv python3-virtualenv
        source python3-virtualenv/bin/activate
        python3 --version
        pip3 install boto3 botocore ansible
        ansible-playbook $WORKSPACE/deploy_db_ansible/deploy_db.yml
        deactivate
        '''
      }
    }
    
    stage ('Configure DB Instance') {
      steps {
        script {
          def userInput = input(id: 'confirm', message: 'Is DB creation complete?', parameters: [ [$class: 'BooleanParameterDefinition', defaultValue: false, description: 'Complete?', name: 'confirm'] ])
        }
        withCredentials([string(credentialsId: 'DB_USERNAME', variable: 'DB_USERNAME'), string(credentialsId: 'DB_PASSWORD', variable: 'DB_PASSWORD'), string(credentialsId: 'DB_NAME', variable: 'DB_NAME'), string(credentialsId: 'SERVER_INSTANCE', variable: 'SERVER_INSTANCE')]){
        sh '''
        USERNAME=${DB_USERNAME}
        PASSWORD=${DB_PASSWORD}
        DBNAME=${DB_NAME}
        SERVER_IP=$(curl -s ipv4.icanhazip.com)
        SERVER_INSTANCE=${SERVER_INSTANCE}
        echo "use ${DB_NAME};" >> $WORKSPACE/db.setup
        echo "UPDATE wp_options SET option_value = '$SERVER_IP' WHERE option_value like '%NLB%'; " >> $WORKSPACE/db.setup

        mysql -u $USERNAME --password=$PASSWORD -h $SERVER_INSTANCE  -D $DBNAME < $WORKSPACE/db.setup
        '''
        }
      }
    }

    stage ('Tear Down CliXX Docker Image and Database') {
      steps {
        script {
          def userInput = input(id: 'confirm', message: 'Tear Down Environment?', parameters: [ [$class: 'BooleanParameterDefinition', defaultValue: false, description: 'Tear Down Environment?', name: 'confirm'] ])
        }
        sh '''
          python3 -m venv python3-virtualenv
          source python3-virtualenv/bin/activate
          python3 --version
          pip3 install boto3 botocore ansible
          ansible-playbook $WORKSPACE/deploy_db_ansible/delete_db.yml
          deactivate
          docker stop clixx-cont
          docker rm clixx-cont
        '''
      }
    }

    stage ('Log Into ECR and push the newly created Docker') {
      steps {
        script {
          def userInput = input(id: 'confirm', message: 'Push Image To ECR?', parameters: [ [$class: 'BooleanParameterDefinition', defaultValue: false, description: 'Push to ECR?', name: 'confirm'] ])
        }
        withCredentials([string(credentialsId: 'ECR_USERNAME', variable: 'ECR_USERNAME'), string(credentialsId: 'ECR_REPO', variable: 'ECR_REPO'), ]){
        sh '''
          aws ecr get-login-password --region us-east-1 | docker login --username ${ECR_USERNAME} --password-stdin ${ECR_REPO}
          docker tag clixx-image:$VERSION ${ECR_REPO}:clixx-image-$VERSION
          docker tag clixx-image:$VERSION ${ECR_REPO}:latest
          docker push ${ECR_REPO}:clixx-image-$VERSION
          docker push ${ECR_REPO}:latest
        '''
        }
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
