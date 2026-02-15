# shopnest-infra-jenkins
""" 
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
                    while (!ready && retries < 12) { // retry for ~2 minutes
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


"""

""" 
🔹 PART 1 — Add Credentials in Jenkins

Go to:

Manage Jenkins → Manage Credentials → Global → Add Credentials


You will add 3 credentials total.

✅ 1️⃣ Add AWS Access Key

Click Add Credentials

Choose:

Kind: Secret text


Fill:

Secret: YOUR_AWS_ACCESS_KEY_ID
ID: aws-access-key
Description: AWS Access Key


Click Save.

✅ 2️⃣ Add AWS Secret Key

Click Add Credentials again

Choose:

Kind: Secret text


Fill:

Secret: YOUR_AWS_SECRET_ACCESS_KEY
ID: aws-secret-key
Description: AWS Secret Key


Click Save.

✅ 3️⃣ Add EC2 SSH Private Key

Click Add Credentials

Choose:

Kind: SSH Username with private key


Fill:

Username: ubuntu
ID: ec2-ssh-key
Private Key: Enter directly → paste your .pem file content


Click Save.
"""

for maunal deployment remove "# " in provider under and 
some commnad for deploy only infre 
aws configer --profile "configs"
enter acess key id, acess key secret, region,
terraform init
terraforn apply
terraform destroy
