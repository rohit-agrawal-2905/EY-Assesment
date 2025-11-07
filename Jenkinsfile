pipeline {
    agent any

    environment {
        PROJECT_ID = 'long-stack-477405-g0'               // 🔹 Replace with your project ID
        CLUSTER_NAME = 'demo-gke-cluster'                // 🔹 Match Terraform output
        CLUSTER_ZONE = 'asia-south1-a'                   // 🔹 Adjust as needed
        IMAGE = "gcr.io/${PROJECT_ID}/nginx-demo"        // 🔹 GCR image name
    }

    stages {

        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/rohit-agrawal-2905/EY-Assessment.git'
            }
        }

        stage('Setup GCP Auth') {
            steps {
                withCredentials([file(credentialsId: 'gcp-service-key', variable: 'GCP_KEY')]) {
                    sh '''
                        echo "Activating GCP Service Account..."
                        gcloud auth activate-service-account --key-file=$GCP_KEY
                        gcloud config set project $PROJECT_ID
                    '''
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                    echo "Building Docker image..."
                    docker build -t $IMAGE:$BUILD_NUMBER .
                '''
            }
        }

        stage('Push to Google Container Registry') {
            steps {
                sh '''
                    echo "Pushing Docker image to GCR..."
                    gcloud auth configure-docker --quiet
                    docker push $IMAGE:$BUILD_NUMBER
                    docker tag $IMAGE:$BUILD_NUMBER $IMAGE:latest
                    docker push $IMAGE:latest
                '''
            }
        }

        stage('Deploy to GKE') {
            steps {
                withCredentials([file(credentialsId: 'gcp-service-key', variable: 'GCP_KEY')]) {
                    sh '''
                        echo "Fetching GKE credentials..."
                        gcloud auth activate-service-account --key-file=$GCP_KEY
                        gcloud container clusters get-credentials $CLUSTER_NAME --zone $CLUSTER_ZONE --project $PROJECT_ID
                        
                        echo "Updating manifests with image tag..."
                        sed -i "s|image: .*|image: $IMAGE:$BUILD_NUMBER|g" k8s/deploy.yaml

                        echo "Deploying to GKE..."
                        kubectl apply -f k8s/
                        kubectl rollout status deployment/nginx-blue
                    '''
                }
            }
        }

        stage('Post Deployment Validation') {
            steps {
                sh '''
                    echo "Listing services..."
                    kubectl get svc
                    echo "Listing pods..."
                    kubectl get pods -o wide
                '''
            }
        }
    }

    post {
        always {
            echo 'Cleaning up workspace...'
            cleanWs()
        }
        success {
            echo '✅ Deployment to GKE successful!'
        }
        failure {
            echo '❌ Deployment failed! Check logs.'
        }
    }
}
