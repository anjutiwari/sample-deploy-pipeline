#!/usr/bin/env sh

export APPSEC_ROOT_PATH=$(pwd)
export APPSEC_TEXT_START="\033[1;32m"
export APPSEC_TEXT_END="\033[0m"
export APPSEC_BOLD_START="\033[0m\033[1m"
export APPSEC_BOLD_END="\033[1;32m"
export APPSEC_IMAGE_VERSION="will01/appsec-101:0.1.0"

function appsec_colour_echo() {
    echo "$APPSEC_TEXT_START $1 $APPSEC_TEXT_END"
}

function appsec_pull() {
    docker pull ${APPSEC_IMAGE_VERSION}
}

function appsec_start_jenkins() {
    docker run -it -d -p 8080:8080 -p 50000:50000 -v jenkins_home:/var/jenkins_home -v /var/run/docker.sock:/var/run/docker.sock --restart unless-stopped ${APPSEC_IMAGE_VERSION} 1>/dev/null
}

function appsec_get_jenkins_admin_creds() {
    DOCKER_IMAGE=$(docker ps -qf "ancestor=${APPSEC_IMAGE_VERSION}")
    if [ -z "$DOCKER_IMAGE" ];
    then
      appsec_colour_echo "    -> error: no docker container found with name ${APPSEC_IMAGE_VERSION}"
    else
      ADMIN_USER=$(docker exec -it $DOCKER_IMAGE cat /var/jenkins_home/secrets/initialAdminPassword)
      appsec_colour_echo "    -> admin password: ${APPSEC_BOLD_START}${ADMIN_USER}${APPSEC_BOLD_END}"
    fi
}

function appsec_list() {
  FUNCTION_LIST=$(grep -E '^function\sappsec' ${APPSEC_ROOT_PATH}/SOURCEME.sh|sed -e 's/function \(appsec.*\)() {/\1/')
  appsec_colour_echo $FUNCTION_LIST
}

function appsec_get_jenkins_shell() {
    docker exec -it $(docker ps -qf "ancestor=${APPSEC_IMAGE_VERSION}") bash
}

function appsec_stop() {
    DOCKER_IMAGE=$(docker ps -qf "ancestor=${APPSEC_IMAGE_VERSION}") 1>/dev/null
    if [ -z "$DOCKER_IMAGE" ];
    then
      appsec_colour_echo "  -> no docker container found with name ${APPSEC_IMAGE_VERSION}"
    else
      docker stop $DOCKER_IMAGE
      appsec_colour_echo "  -> docker container with name ${APPSEC_IMAGE_VERSION} and id $DOCKER_IMAGE has been stopped."
    fi
}

function appsec_cleanup() {
    appsec_colour_echo "  -> stopping ${APPSEC_IMAGE_VERSION} container..."
    appsec_stop
    appsec_colour_echo "  -> removing ${APPSEC_IMAGE_VERSION} image..."
    docker image rm ${APPSEC_IMAGE_VERSION} --force
    appsec_colour_echo "  -> pruning dangling images..."
    docker image prune --force
    appsec_colour_echo "  -> pruning dangling containers..."
    docker container prune --force
    appsec_colour_echo "  -> removing jenkins-home volume..."
    docker volume rm jenkins_home
}

function appsec_start() {
    appsec_colour_echo "Starting appsec sample-deploy-pipeline with docker image ${APPSEC_IMAGE_VERSION}..."
    appsec_colour_echo "  -> Cleaning up any previous run of sample-deploy-pipeline..."
    appsec_cleanup
    appsec_colour_echo "  -> Pulling docker image for ${APPSEC_IMAGE_VERSION}..."
    appsec_pull
    appsec_colour_echo "  -> Starting docker container for ${APPSEC_IMAGE_VERSION}..."
    appsec_start_jenkins
    appsec_colour_echo "  -> Sleeping for 30 seconds before retrieving credentials..."
    sleep 30s
    appsec_colour_echo "  -> Retrieving Jenkins admin credentials from Jenkins..."
    appsec_get_jenkins_admin_creds
    appsec_colour_echo "  -> To access the Jenkins server, browse to '${APPSEC_BOLD_START}http://localhost:8080${APPSEC_BOLD_END}'."
}

appsec_colour_echo "AppSec helper functions have been added to your command line."
appsec_colour_echo "  -> for a list of appsec helper functions type '${APPSEC_BOLD_START}appsec_list${APPSEC_BOLD_END}'."
appsec_colour_echo "  -> to start the application type '${APPSEC_BOLD_START}appsec_start${APPSEC_BOLD_END}'."
appsec_colour_echo "  -> to stop the application type '${APPSEC_BOLD_START}appsec_stop${APPSEC_BOLD_END}'."
appsec_colour_echo "  -> to cleanup the application type '${APPSEC_BOLD_START}appsec_cleanup${APPSEC_BOLD_END}'."
