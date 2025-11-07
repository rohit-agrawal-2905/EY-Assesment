pipeline {
    agent any
    
    environment {
        PROJECT_ID = 'long-stack-477405-g0'
        CLUSTER_NAME = 'demo-gke-cluster'
        CLUSTER_ZONE = 'asia-south1-a'
        GCP_KEY = credentials('gcp-service-key')
        // Demo configuration
        DEMO_ENABLED = 'true'  // Set to 'false' to skip autoscaling demo
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
        
        stage('Deploy to GKE') {
            steps {
                sh '''
                    echo "🚀 Applying Kubernetes manifests..."
                    kubectl apply -f k8s/deployment.yaml
                    kubectl apply -f k8s/service.yaml
                    kubectl apply -f k8s/hpa.yaml
                    kubectl apply -f k8s/load-generator.yaml
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
        
        stage('Autoscaling Demo - Setup') {
            when {
                environment name: 'DEMO_ENABLED', value: 'true'
            }
            steps {
                script {
                    echo "📊 =========================================="
                    echo "📊 Starting Autoscaling Demo"
                    echo "📊 =========================================="
                }
                sh '''
                    echo "⚙️  Configuring HPA threshold to ${HPA_THRESHOLD}% for demo..."
                    kubectl patch hpa nginx-hpa --type='json' -p='[{"op": "replace", "path": "/spec/metrics/0/resource/target/averageUtilization", "value": '${HPA_THRESHOLD}'}]'
                    
                    echo "📋 Current HPA Configuration:"
                    kubectl get hpa nginx-hpa -o wide
                    
                    echo "📋 Initial Pod Count:"
                    kubectl get pods -l app=nginx-blue --no-headers | wc -l
                '''
            }
        }
        
        stage('Autoscaling Demo - Scale UP') {
            when {
                environment name: 'DEMO_ENABLED', value: 'true'
            }
            steps {
                script {
                    echo "🔥 =========================================="
                    echo "🔥 Phase 1: Triggering Scale UP"
                    echo "🔥 =========================================="
                }
                sh '''
                    echo "🚀 Starting load generation with ${LOAD_REPLICAS} replicas..."
                    kubectl scale deployment load-generator --replicas=${LOAD_REPLICAS}
                    
                    echo "⏳ Waiting for load generators to start..."
                    sleep 10
                    
                    echo "📊 Load generator status:"
                    kubectl get pods -l app=load-generator
                    
                    echo ""
                    echo "⏳ Monitoring HPA scale UP for 90 seconds..."
                    echo "================================================"
                    
                    for i in $(seq 1 18); do
                        echo ""
                        echo "--- Check $i/18 (every 5 seconds) ---"
                        echo -n "HPA Status: "
                        kubectl get hpa nginx-hpa --no-headers | awk '{print "Target: "$5" | Replicas: "$7"/"$8}'
                        
                        echo -n "Active Pods: "
                        kubectl get pods -l app=nginx-blue --no-headers | grep -c "Running" || echo "0"
                        
                        echo -n "Pending Pods: "
                        kubectl get pods -l app=nginx-blue --no-headers | grep -c "Pending\\|ContainerCreating" || echo "0"
                        
                        sleep 5
                    done
                    
                    echo ""
                    echo "📊 Final Scale UP Status:"
                    kubectl get hpa nginx-hpa
                    kubectl get pods -l app=nginx-blue
                '''
            }
        }
        
        stage('Autoscaling Demo - Scale DOWN') {
            when {
                environment name: 'DEMO_ENABLED', value: 'true'
            }
            steps {
                script {
                    echo "🛑 =========================================="
                    echo "🛑 Phase 2: Triggering Scale DOWN"
                    echo "🛑 =========================================="
                }
                sh '''
                    echo "🛑 Stopping load generation..."
                    kubectl scale deployment load-generator --replicas=0
                    
                    echo "⏳ Waiting for load to decrease..."
                    sleep 15
                    
                    echo ""
                    echo "⏳ Monitoring HPA scale DOWN for 150 seconds..."
                    echo "================================================"
                    
                    for i in $(seq 1 30); do
                        echo ""
                        echo "--- Check $i/30 (every 5 seconds) ---"
                        echo -n "HPA Status: "
                        kubectl get hpa nginx-hpa --no-headers | awk '{print "Target: "$5" | Replicas: "$7"/"$8}'
                        
                        echo -n "Active Pods: "
                        kubectl get pods -l app=nginx-blue --no-headers | grep -c "Running" || echo "0"
                        
                        echo -n "Terminating Pods: "
                        kubectl get pods -l app=nginx-blue --no-headers | grep -c "Terminating" || echo "0"
                        
                        sleep 5
                    done
                    
                    echo ""
                    echo "📊 Final Scale DOWN Status:"
                    kubectl get hpa nginx-hpa
                    kubectl get pods -l app=nginx-blue
                '''
            }
        }
        
        stage('Autoscaling Demo - Cleanup') {
            when {
                environment name: 'DEMO_ENABLED', value: 'true'
            }
            steps {
                script {
                    echo "🧹 =========================================="
                    echo "🧹 Cleaning up demo resources"
                    echo "🧹 =========================================="
                }
                sh '''
                    echo "🧹 Removing load generator deployment..."
                    kubectl delete deployment load-generator --ignore-not-found=true
                    
                    echo "✅ Demo cleanup complete!"
                    echo ""
                    echo "📊 Final Cluster State:"
                    kubectl get hpa nginx-hpa
                    kubectl get pods -l app=nginx-blue
                    kubectl get svc nginx-service
                '''
            }
        }
        
        stage('Final Verification') {
            steps {
                sh '''
                    echo "🎯 =========================================="
                    echo "🎯 Final Deployment Verification"
                    echo "🎯 =========================================="
                    echo ""
                    echo "📦 All Deployments:"
                    kubectl get deployments
                    echo ""
                    echo "🔌 All Services:"
                    kubectl get svc
                    echo ""
                    echo "📊 HPA Status:"
                    kubectl get hpa
                    echo ""
                    echo "🏃 Running Pods:"
                    kubectl get pods -l app=nginx-blue
                '''
            }
        }
    }
    
    post {
        success {
            script {
                echo "✅ =========================================="
                echo "✅ Pipeline Completed Successfully!"
                echo "✅ =========================================="
                if (env.DEMO_ENABLED == 'true') {
                    echo "📊 Autoscaling demo executed successfully"
                }
                echo "🌐 Access your application at:"
                sh 'kubectl get svc nginx-service -o jsonpath="{.status.loadBalancer.ingress[0].ip}" || echo "LoadBalancer IP pending..."'
            }
        }
        failure {
            echo "❌ =========================================="
            echo "❌ Pipeline Failed! Check logs above."
            echo "❌ =========================================="
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
