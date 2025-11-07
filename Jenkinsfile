pipeline {
    agent any

    environment {
        PROJECT_ID = 'long-stack-477405-g0'
        CLUSTER_NAME = 'demo-gke-cluster'
        CLUSTER_ZONE = 'asia-south1-a'
        GCP_KEY = credentials('gcp-key')
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/rohit-agrawal-2905/EY-Assesment.git'
            }
        }

        stage('Setup GCP Auth') {
            steps {
                withCredentials([file(credentialsId: 'gcp-key', variable: 'GCP_KEY')]) {
                    sh '''
                      echo "🔑 Activating GCP Service Account..."
                      gcloud auth activate-service-account --key-file=$GCP_KEY
                      gcloud config set project $PROJECT_ID
                    '''
                }
            }
        }

        stage('Get GKE Credentials') {
            steps {
                sh '''
                  echo "🎯 Getting GKE credentials..."
                  gcloud container clusters get-credentials $CLUSTER_NAME --zone $CLUSTER_ZONE --project $PROJECT_ID
                '''
            }
        }

        stage('Deploy to GKE') {
            steps {
                sh '''
                  echo "🚀 Applying Kubernetes manifests..."
                  kubectl apply -f k8s/deployment.yaml
                  kubectl apply -f k8s/service.yaml
                  kubectl apply -f k8s/hpa.yaml
                '''
            }
        }

        stage('Verify Deployment') {
            steps {
                sh '''
                  echo "🔍 Checking Deployment Status..."
                  kubectl get pods
                  kubectl get svc
                  kubectl get hpa
                '''
            }
        }
    }

    post {
        success {
            echo '✅ Deployment successful!'
        }
        failure {
            echo '❌ Deployment failed! Check logs.'
        }
    }
}
