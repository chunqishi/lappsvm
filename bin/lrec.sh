#!/bin/sh

LREC_DIR=$(pwd)
PROJECT_DIR="$HOME/Project"
LDDL_GIT_HUB="https://github.com/chunqishi/lapps_lddl_brandeis.git"
WS_GIT_HUB="https://github.com/chunqishi/org.lappsgrid.example.java.helloworld.git"
TOMCAT6_HOME="$PROJECT_DIR/apache-tomcat-6.0.39/"
TOMCAT6_SERVER="http://localhost:8080"
SERVICE_MANAGER="${TOMCAT6_SERVER}/service_manager"

function deploy_git_2_tomcat {
    git_url=$1
    tomcat_home=$2

    local_dir=${git_url##*/}
    local_dir=${PROJECT_DIR}/${local_dir%%.git*}
    git clone ${git_url} ${local_dir}

    cd ${local_dir}
    mvn clean package
    ${tomcat_home}/bin/shutdown.sh
    sleep 2
    package=$(ls ${local_dir}/target/*.war)
    package=${package##*/}
    package=${package%%.war*}
    cp ${local_dir}/target/*.war ${tomcat_home}/webapps/
    ${tomcat_home}/bin/startup.sh
    sleep 10
    service_manager_page="$(wget -qO- ${TOMCAT6_SERVER}/${package}/services)"
    if [[ ${service_manager_page} == *Services* ]]; then
      echo "Deploy works !"
    else
      echo "Deploy DOES NOT work !"
    fi
}

cd ${LREC_DIR}

echo ""
echo "Prepare \"Project\" directory ..."
echo ""
if [[ -d "${PROJECT_DIR}" ]]; then
echo "${PROJECT_DIR} already exists ."
else
mkdir "${PROJECT_DIR}"
fi


cd "${PROJECT_DIR}"


echo ""
echo "Deploy Services ..."
echo "------------- Deploy ---------------------"
echo ""

echo
echo "Running Git ..."
echo "<------------ Git Clone  ------------------"
git clone ${LDDL_GIT_HUB} ${PROJECT_DIR}/lddl

echo
echo "Running Maven ..."
echo "<------------ Maven Package ------------------"
deploy_git_2_tomcat "${WS_GIT_HUB}" "${TOMCAT6_HOME}"


echo
echo "Running LDDL ..."
echo "<------------ LDDL RUN  ------------------"
${PROJECT_DIR}/lddl/bin/lddl.sh ${PROJECT_DIR}/lddl/src/lddl-scripts/Deploy.lddl clean

echo ""
echo "${SERVICE_MANAGER}"
echo ""

#
