pipeline {
  agent {
    docker {
      image '${AWS_ACCOUNT_ID}.dkr.ecr.ap-southeast-1.amazonaws.com/internal/terraform:0.12.8.1-alpine-3.10-awscli-1.16.279'
      registryUrl 'https://${AWS_ACCOUNT_ID}.dkr.ecr.ap-southeast-1.amazonaws.com/'
      args '--privileged -v $DOCKER_CONFIG/:/root/.docker/'
    }
  }

  environment {
    TF_VAR_role_arn    = credentials('TF_VAR_role_arn')
    TF_VAR_external_id = credentials('TF_VAR_external_id')
    TF_VAR_flux_ssh_key = credentials('TF_VAR_flux_ssh_key')
  }

  stages {
    stage('Terraform Init Modules') {
      steps {
        sh 'cd terraform/env/dev/ && terraform init -backend-config="role_arn=arn:aws:iam::${AWS_ACCOUNT_ID}:role/${TF_VAR_role_arn}" -backend-config="external_id=${TF_VAR_external_id}"'
      }
      post {
        failure {
          githubNotify status: 'FAILURE',
                       description: "Terraform Init Modules",
                       context: "jenkins: /terrform/init"
        }

        success {
          githubNotify status: 'SUCCESS',
                       description: "Terraform Init Modules",
                       context: "jenkins: /terrform/init"
        }
      }
    }

    stage('Terraform Planning for Checking') {
      steps {
        sh 'cd terraform/env/dev && terraform plan --detailed-exitcode -input=false || ([ "$?" -eq "2" ] && exit 0);'
      }
      post {
        failure {
          githubNotify status: 'FAILURE',
                       description: "Terraform Planning for Checking",
                       context: "jenkins: /terrform/plan"
        }
        success {
          githubNotify status: 'SUCCESS',
                       description: "Terraform Planning for Checking",
                       context: "jenkins: /terrform/plan"
        }
      }
    }

    stage('Terraform deploy to AWS Cloud') {
      //when {
      //  branch 'master'
      //  beforeInput true
      //}
      options {
        timeout(time: 1, unit: "DAYS")
      }

      input {
        message "Please choose the exact environment (dev,stg,prod) you want to deploy to? Be careful!"
        ok "Yes"
        submitter "admin"
        parameters {
          string(name: 'Environment', defaultValue: 'dev')
        }
      }

      steps {
        sh 'cd terraform/env/${Environment} && terraform apply -input=false -auto-approve'
      }

      post {
      failure {
        mail to: 'pmquang1990@gmail.com',
             subject: "Failed Pipeline: ${currentBuild.fullDisplayName}",
             body: "Deployment error at ${env.BUILD_URL}. It's critical error, please check it out!"
      }}
    }
  }
}
