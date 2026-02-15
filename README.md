# shopnest-infra-jenkins

## Complete Deployment Guide (Jenkins + Terraform + AWS)

---

## Prerequisites (On Jenkins Server)

Make sure the Jenkins server has the following installed:

- Jenkins
- Terraform
- AWS CLI
- Git

---

## Jenkins Credentials Setup (Required Before Running Pipeline)

Go to:

Manage Jenkins → Manage Credentials → Global → Add Credentials

You must add **3 credentials**:

### 1️⃣ AWS Access Key
Choose:
- Kind: **Secret text** 
Fill:
- Secret: `YOUR_AWS_ACCESS_KEY_ID`
- ID: `aws-access-key`
- Description: AWS Access Key

### 2️⃣ AWS Secret Access Key
- Kind: **Secret text**
- Secret: `YOUR_AWS_SECRET_ACCESS_KEY`
- ID: `aws-secret-key`
- Description: AWS Secret Key

### 3️⃣ EC2 SSH Private Key
- Kind: **SSH Username with private key**
- Username: `ubuntu`
- ID: `ec2-ssh-key`
- Private Key: Select **Enter directly** and paste your `.pem` file content

Click **Save** after adding each credential.

---

## Jenkins Pipeline Configuration

Add the following pipeline script inside your Jenkins job:

```groovy
pipeline {
    agent any

    environment {
        SSH_KEY              = credentials('ec2-ssh-key')
        AWS_ACCESS_KEY_ID     = credentials('aws-access-key')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-key')
        AWS_DEFAULT_REGION    = "eu-west-1"
    }

    stages {

        stage('Clone Terraform Repo') {
            steps {
                dir('terraform-repo') {
                    git branch: 'main', url: 'https://github.com/shriballal30-svg/shopnest-infra-jenkins.git'
                }
            }
        }

        stage('Terraform Init & Apply') {
            steps {
                dir('terraform-repo') {
                    sh '''
                    terraform init
                    terraform apply -auto-approve
                    '''
                }
            }
        }

        stage('Get EC2 Public IP') {
            steps {
                script {
                    def ip = sh(
                        script: "cd terraform-repo && terraform output -raw ec2_public_ip",
                        returnStdout: true
                    ).trim()
                    env.EC2_IP = ip
                }
            }
        }

        stage('Wait for EC2 SSH Ready') {
            steps {
                script {
                    echo "Waiting for EC2 to be ready..."
                    def ready = false
                    int retries = 0
                    while (!ready && retries < 12) {
                        try {
                            sh "ssh -o StrictHostKeyChecking=no -i $SSH_KEY ubuntu@${EC2_IP} 'echo ready'"
                            ready = true
                        } catch (Exception e) {
                            echo "EC2 not ready yet. Retrying in 10 seconds..."
                            sleep 10
                            retries++
                        }
                    }
                    if (!ready) {
                        error("EC2 did not become ready in time")
                    }
                }
            }
        }

        stage('Deploy Application on EC2') {
            steps {
                sh """
                ssh -o StrictHostKeyChecking=no -i $SSH_KEY ubuntu@${EC2_IP} '
                git clone https://github.com/shriballal30-svg/shopnest.git
                cd shopnest
                cd shopnest
                sed -i "s/MY_IP/${EC2_IP}/g" .env
                sed -i "s/MY_IP/${EC2_IP}/g" frontend/src/App.jsx
                ./deploy.sh
                '
                """
            }
        }
    }
}
