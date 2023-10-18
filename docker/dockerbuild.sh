docker build -t ${ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com/${REPO} . -f ./docker/Dockerfile

aws ecr get-login-password \
    --region ${REGION} \
| docker login \
    --username AWS \
    --password-stdin ${ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com

docker push ${ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com/${REPO}