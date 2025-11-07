pipeline {
    agent any
    
    environment {
        PROJECT_ID = 'long-stack-477405-g0'
        CLUSTER_NAME = 'demo-gke-cluster'
        CLUSTER_ZONE = 'asia-south1-a'
        GCP_KEY = credentials('gcp-service-key')
        DEMO_ENABLED = 'true'
        LOAD_REPLICAS = '20'
        HPA_THRESHOLD = '25'
    }
    
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/rohit-agrawal-2905/EY-Assesment.git'
            }
        }

        stage('Setup GCP Auth') {
            steps {
                withCredentials([file(credentialsId: 'gcp-service-key', variable: 'GCP_KEY')]) {
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

        stage('Blue-Green Deployment') {
            steps {
                script {
                    echo "🌈 Starting Blue-Green Deployment..."

                    // Detect which color is active (default to blue if not found)
                    def currentColor = ""
                    try {
                        currentColor = sh(script: "kubectl get svc nginx-service -o jsonpath='{.spec.selector.color}'", returnStdout: true).trim()
                    } catch (err) {
                        echo "⚠️ Service not found or color not set. Defaulting to 'blue' as current."
                        currentColor = "blue"
                    }

                    def newColor = (currentColor == "blue") ? "green" : "blue"

                    echo "🟦 Current live color: ${currentColor}"
                    echo "🟩 Deploying new color: ${newColor}"

                    // Deploy new version
                    sh "kubectl apply -f k8s/deployment-${newColor}.yaml"

                    echo "⏳ Waiting for rollout of nginx-${newColor}..."
                    sh "kubectl rollout status deployment/nginx-${newColor}"

                    // Switch the service to point to the new color
                    echo "🔁 Switching nginx-service to color: ${newColor}"
                    sh "kubectl patch svc nginx-service -p '{\"spec\": {\"selector\": {\"app\": \"nginx\", \"color\": \"${newColor}\"}}}'"

                    echo "🧹 Cleaning up old deployment: nginx-${currentColor}"
                    sh "kubectl delete deployment nginx-${currentColor} --ignore-not-found=true"

                    echo "✅ Blue-Green Deployment complete! Active color: ${newColor}"
                }
            }
        }

        stage('Apply Supporting Resources') {
            steps {
                sh '''
                    echo "⚙️ Applying supporting Kubernetes resources..."
                    kubectl apply -f k8s/hpa.yaml
                    kubectl apply -f k8s/load-generator.yaml
                '''
            }
        }

        stage('Verify Deployment') {
            steps {
                sh '''
                    echo "🔍 Verifying Deployment..."
                    kubectl get pods -l app=nginx
                    kubectl get svc nginx-service
                    kubectl get hpa
                '''
            }
        }

        stage('Autoscaling Demo - Setup') {
            when {
                environment name: 'DEMO_ENABLED', value: 'true'
            }
            steps {
                script {
                    echo "📊 Starting Autoscaling Demo Setup..."
                }
                sh '''
                    kubectl patch hpa nginx-hpa --type='json' \
                        -p='[{"op": "replace", "path": "/spec/metrics/0/resource/target/averageUtilization", "value": '${HPA_THRESHOLD}'}]'
                    
                    kubectl get hpa nginx-hpa -o wide
                    kubectl get pods -l app=nginx
                '''
            }
        }

        stage('Autoscaling Demo - Scale UP') {
            when {
                environment name: 'DEMO_ENABLED', value: 'true'
            }
            steps {
                script {
                    echo "🔥 Triggering Scale UP..."
                }
                sh '''
                    kubectl scale deployment load-generator --replicas=${LOAD_REPLICAS}
                    sleep 10
                    for i in $(seq 1 18); do
                        echo "--- Check $i/18 ---"
                        kubectl get hpa nginx-hpa --no-headers | awk '{print "Target: "$5" | Replicas: "$7"/"$8}'
                        kubectl get pods -l app=nginx | grep Running | wc -l
                        sleep 5
                    done
                '''
            }
        }

        stage('Autoscaling Demo - Scale DOWN') {
            when {
                environment name: 'DEMO_ENABLED', value: 'true'
            }
            steps {
                script {
                    echo "🛑 Triggering Scale DOWN..."
                }
                sh '''
                    kubectl scale deployment load-generator --replicas=0
                    sleep 15
                    for i in $(seq 1 30); do
                        echo "--- Check $i/30 ---"
                        kubectl get hpa nginx-hpa --no-headers | awk '{print "Target: "$5" | Replicas: "$7"/"$8}'
                        kubectl get pods -l app=nginx | grep Running | wc -l
                        sleep 5
                    done
                '''
            }
        }

        stage('Autoscaling Demo - Cleanup') {
            when {
                environment name: 'DEMO_ENABLED', value: 'true'
            }
            steps {
                sh '''
                    echo "🧹 Cleaning up load generator..."
                    kubectl delete deployment load-generator --ignore-not-found=true
                    echo "✅ Demo cleanup complete!"
                '''
            }
        }

        stage('Final Verification') {
            steps {
                sh '''
                    echo "🎯 Final Verification..."
                    kubectl get deployments
                    kubectl get svc
                    kubectl get hpa
                    kubectl get pods -l app=nginx
                '''
            }
        }
    }

    post {
        success {
            script {
                echo "✅ Pipeline Completed Successfully!"
                echo "🌐 Access your application at:"
                sh 'kubectl get svc nginx-service -o jsonpath="{.status.loadBalancer.ingress[0].ip}" || echo "LoadBalancer IP pending..."'
            }
        }
        failure {
            echo "❌ Pipeline Failed!"
            sh '''
                echo "📋 Current cluster state:"
                kubectl get all
            '''
        }
        always {
            echo "🏁 Pipeline execution completed at: ${new Date()}"
        }
    }
}
