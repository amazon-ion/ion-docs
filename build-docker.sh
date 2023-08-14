#!/bin/bash

# Arguments are passed-through to Rake.

source run_check.sh

set -e

IMAGE_TAG="ion-spec-asciidoc"

#DOCKER_ARGS="--platform linux/amd64"
DOCKER_ARGS=""

function build_image()
{
  run_check docker build ${DOCKER_ARGS} \
    --tag "${IMAGE_TAG}" \
    --build-arg USER_ID="$(id -u)" \
    --build-arg GROUP_ID="$(id -g)" \
    "$(pwd)"
}

function run_inside()
{
  #  --rm Automatically remove the container when it exits

  run_check docker run ${DOCKER_ARGS} \
    --interactive --tty --rm \
    --mount type=bind,source="$(pwd)",target=/workspace \
    "${IMAGE_TAG}" \
    "$@"
}

function execute_build_logic()
{
  run_inside /bin/bash --login docker-run.sh "$@"
}

function start_shell()
{
  run_inside /bin/bash "$@"
}


#===============================================================================


function usage()
{
    echo "Usage: " "$0" "[-h] [-r] [-b] [-s]"
    echo
    echo " -h  Show this help."
    echo " -u  Update the Docker image."
    echo " -b  Execute the build logic inside a new container."
    echo " -s  Start a shell inside a new container."
    echo
    echo "By default, when none of -ubs are given then -ub is assumed."
}

while getopts ":ubsh" o; do
  case "$o" in
    h) usage; exit;;
    u) do_update=true;;
    b) do_build=true;;
    s) do_shell=true;;
    *) echo "illegal option -$OPTARG"; usage; exit 1;;
  esac
done
shift $((OPTIND-1))
unset OPTIND

if [[ -z $do_update$do_build$do_shell ]]
then
  do_update=true
  do_build=true
fi

# FIXME -bs should give a shell inside the -b container.
if [[ $do_build$do_shell = truetrue ]]
then
  echo "WARNING: -b and -s use separate containers!"
fi

[[ -n $do_update ]] && build_image
[[ -n $do_build  ]] && execute_build_logic "$@"
[[ -n $do_shell  ]] && start_shell "$@"
