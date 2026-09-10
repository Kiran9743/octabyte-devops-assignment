```groovy
pipeline {
    agent any

    environment {
        AWS_REGION    = 'ap-south-1'
        EKS_CLUSTER   = 'octabyte-staging-eks'
        K8S_NAMESPACE = 'staging'

        AWS_ACCOUNT_ID = '507941514830'
        ECR_REPOSITORY = 'octabyte/staging/app'

        IMAGE_NAME = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY}"
        IMAGE_TAG  = "${env.GIT_COMMIT}"
        IMAGE_URI  = "${IMAGE_NAME}:${env.GIT_COMMIT}"

        DEPLOYMENT_NAME = 'octa-app'
        CONTAINER_NAME  = 'octa-app'

        KUBECONFIG_PATH = '/var/lib/jenkins/.kube/config'
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm

                script {
                    env.GIT_COMMIT = sh(
                        script: 'git rev-parse HEAD',
                        returnStdout: true
                    ).trim()

                    env.IMAGE_TAG = env.GIT_COMMIT
                    env.IMAGE_URI = "${env.IMAGE_NAME}:${env.IMAGE_TAG}"

                    echo "Git commit: ${env.GIT_COMMIT}"
                    echo "Docker image: ${env.IMAGE_URI}"
                }
            }
        }

        stage('Validate Application') {
            steps {
                sh '''
                    set -eux

                    test -f app/app.py
                    test -f app/Dockerfile
                    test -f app/requirements.txt

                    python3 --version || true
                    docker --version
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                    set -eux

                    docker build \
                      --pull \
                      -t "${IMAGE_URI}" \
                      -t "${IMAGE_NAME}:ci-${BUILD_NUMBER}" \
                      ./app

                    docker image inspect "${IMAGE_URI}" > /dev/null
                '''
            }
        }

        stage('Container Health Test') {
            steps {
                sh '''
                    set -eux

                    docker rm -f octabyte-ci-test 2>/dev/null || true

                    docker run -d \
                      --name octabyte-ci-test \
                      -p 18000:8000 \
                      -e APP_ENV=staging \
                      "${IMAGE_URI}"

                    trap 'docker rm -f octabyte-ci-test 2>/dev/null || true' EXIT

                    echo "Waiting for application..."

                    for i in $(seq 1 30); do
                        if curl --fail --silent http://127.0.0.1:18000/health; then
                            echo
                            echo "Application health check passed."
                            exit 0
                        fi

                        sleep 2
                    done

                    echo "Application failed health check."

                    docker logs octabyte-ci-test || true
                    exit 1
                '''
            }
        }

        stage('Trivy Security Scan') {
            steps {
                sh '''
                    set -eux

                    docker run --rm \
                      -v /var/run/docker.sock:/var/run/docker.sock \
                      -v "${WORKSPACE}:/workspace:ro" \
                      aquasec/trivy:latest \
                      image \
                      --severity HIGH,CRITICAL \
                      --ignore-unfixed \
                      --exit-code 1 \
                      "${IMAGE_URI}"
                '''
            }
        }

        stage('Login to ECR') {
            steps {
                sh '''
                    set -eux

                    aws sts get-caller-identity

                    aws ecr get-login-password \
                      --region "${AWS_REGION}" \
                    | docker login \
                      --username AWS \
                      --password-stdin \
                      "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
                '''
            }
        }

        stage('Push Image to ECR') {
            steps {
                sh '''
                    set -eux

                    if aws ecr describe-images \
                        --repository-name "${ECR_REPOSITORY}" \
                        --image-ids imageTag="${IMAGE_TAG}" \
                        --region "${AWS_REGION}" > /dev/null 2>&1; then

                        echo "Image ${IMAGE_URI} already exists in ECR."
                        echo "Skipping push because the repository is immutable."

                    else

                        docker push "${IMAGE_URI}"

                    fi
                '''
            }
        }

        stage('Configure EKS Access') {
            steps {
                sh '''
                    set -eux

                    mkdir -p "$(dirname "${KUBECONFIG_PATH}")"

                    aws eks update-kubeconfig \
                      --region "${AWS_REGION}" \
                      --name "${EKS_CLUSTER}" \
                      --kubeconfig "${KUBECONFIG_PATH}"

                    kubectl \
                      --kubeconfig "${KUBECONFIG_PATH}" \
                      get namespace "${K8S_NAMESPACE}"
                '''
            }
        }

        stage('Deploy to Staging') {
            steps {
                sh '''
                    set -eux

                    kubectl \
                      --kubeconfig "${KUBECONFIG_PATH}" \
                      -n "${K8S_NAMESPACE}" \
                      set image deployment/"${DEPLOYMENT_NAME}" \
                      "${CONTAINER_NAME}"="${IMAGE_URI}"

                    kubectl \
                      --kubeconfig "${KUBECONFIG_PATH}" \
                      -n "${K8S_NAMESPACE}" \
                      annotate deployment/"${DEPLOYMENT_NAME}" \
                      kubernetes.io/change-cause="Jenkins deployment ${BUILD_NUMBER} - ${GIT_COMMIT}" \
                      --overwrite
                '''
            }
        }

        stage('Rollout Verification') {
            steps {
                sh '''
                    set -eux

                    kubectl \
                      --kubeconfig "${KUBECONFIG_PATH}" \
                      -n "${K8S_NAMESPACE}" \
                      rollout status \
                      deployment/"${DEPLOYMENT_NAME}" \
                      --timeout=5m

                    kubectl \
                      --kubeconfig "${KUBECONFIG_PATH}" \
                      -n "${K8S_NAMESPACE}" \
                      get deployment "${DEPLOYMENT_NAME}"

                    kubectl \
                      --kubeconfig "${KUBECONFIG_PATH}" \
                      -n "${K8S_NAMESPACE}" \
                      get pods \
                      -l app="${DEPLOYMENT_NAME}" \
                      -o wide
                '''
            }
        }

        stage('Verify Application') {
            steps {
                sh '''
                    set -eux

                    READY=$(kubectl \
                      --kubeconfig "${KUBECONFIG_PATH}" \
                      -n "${K8S_NAMESPACE}" \
                      get deployment "${DEPLOYMENT_NAME}" \
                      -o jsonpath='{.status.readyReplicas}')

                    DESIRED=$(kubectl \
                      --kubeconfig "${KUBECONFIG_PATH}" \
                      -n "${K8S_NAMESPACE}" \
                      get deployment "${DEPLOYMENT_NAME}" \
                      -o jsonpath='{.spec.replicas}')

                    echo "Ready replicas: ${READY}"
                    echo "Desired replicas: ${DESIRED}"

                    test "${READY}" = "${DESIRED}"

                    echo "Staging deployment is healthy."
                '''
            }
        }
    }

    post {
        always {
            sh '''
                docker rm -f octabyte-ci-test 2>/dev/null || true
                docker logout "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com" 2>/dev/null || true
            '''
        }

        success {
            echo "Jenkins CI/CD pipeline completed successfully."
            echo "Image deployed: ${IMAGE_URI}"
            echo "Environment: staging"
        }

        failure {
            echo "Jenkins CI/CD pipeline failed."
            echo "Check the failed stage above."
        }
    }
}
```
