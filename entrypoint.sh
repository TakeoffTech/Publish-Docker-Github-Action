#!/bin/sh
set -e

if [ -z "${INPUT_NAME}" ]; then
  echo "Unable to find the repository name. Did you set with.name?"
  exit 1
fi

if [ -z "${INPUT_USERNAME}" ]; then
  echo "Unable to find the username. Did you set with.username?"
  exit 1
fi

if [ -z "${INPUT_PASSWORD}" ]; then
  echo "Unable to find the password. Did you set with.password?"
  exit 1
fi

BRANCH=${GITHUB_REF##refs/*/}

if [ "${BRANCH}" == "master" ]; then
  BRANCH="latest"
fi;

# if contains /refs/tags/
if [ $(echo ${GITHUB_REF} | sed -e "s/refs\/tags\///g") != ${GITHUB_REF} ]; then
  BRANCH="latest"
fi;

echo ${INPUT_PASSWORD} | docker login -u ${INPUT_USERNAME} --password-stdin ${INPUT_REGISTRY}

if [ "${INPUT_REGISTRY}" == "docker.pkg.github.com" ]; then
  BASE_NAME="${INPUT_REGISTRY}/$(echo ${GITHUB_REPOSITORY} | tr "[:upper:]" "[:lower:]")/${INPUT_NAME}"
else
  BASE_NAME="${INPUT_NAME}"
fi

DOCKERNAME="${BASE_NAME}:${BRANCH}"
BUILDPARAMS="${INPUT_EXTRA_BUILD_PARAMS}"

if [ ! -z "${INPUT_DOCKERNAME_APPENDIX}" ]; then
  DOCKERNAME="$DOCKERNAME${INPUT_DOCKERNAME_APPENDIX}"
fi

if [ ! -z "${INPUT_DOCKERFILE}" ]; then
  BUILDPARAMS="$BUILDPARAMS -f ${INPUT_DOCKERFILE}"
  # trims the '/Dockerfile' from path/to/Dockerfile 
  CONTEXT=${INPUT_DOCKERFILE%/*}
  if [ "${INPUT_DOCKERFILE}" == "${CONTEXT}" ]; then CONTEXT="."; fi
else
  CONTEXT="."
fi

if [ ! -z "${INPUT_CACHE}" ]; then
  docker pull ${DOCKERNAME}
  BUILDPARAMS="$BUILDPARAMS --cache-from ${DOCKERNAME}"
fi

if [ "${INPUT_SNAPSHOT}" == "true" ]; then
  timestamp=`date +%Y%m%d%H%M%S`
  shortSha=$(echo "${GITHUB_SHA}" | cut -c1-6)
  SHA_DOCKER_NAME="${BASE_NAME}:${timestamp}${shortSha}"
  docker build $BUILDPARAMS -t ${DOCKERNAME} -t ${SHA_DOCKER_NAME} ${CONTEXT}
  docker push ${DOCKERNAME}
  docker push ${SHA_DOCKER_NAME}
elif [ "${INPUT_TAGGING}" == "true" ]; then
  DOCKER_TAG=$(echo ${GITHUB_REF} | sed -e 's/refs\/tags\/v//')
  docker build $BUILDPARAMS -t ${BASE_NAME}:latest -t ${BASE_NAME}:${DOCKER_TAG} ${CONTEXT}
  docker push ${BASE_NAME}:latest
  docker push ${BASE_NAME}:${DOCKER_TAG}
else
  docker build $BUILDPARAMS -t ${DOCKERNAME} ${CONTEXT}
  docker push ${DOCKERNAME}
fi

docker logout
