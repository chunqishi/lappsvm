#!/bin/sh

LREC_DIR=$(pwd)
PROJECT_DIR="$HOME/Project"
LDDL_GIT_HUB="https://github.com/chunqishi/lapps_lddl_brandeis.git"
WS_GIT_HUB="https://github.com/chunqishi/edu.brandeis.cs.template-web-service.git"
TOMCAT6_HOME="$PROJECT_DIR/apache-tomcat-6.0.39/"

USER_PASSWD="lappsgrid"


function deploy_git_2_tomcat {
    git_url=$1
    tomcat_home=$2

    local_dir=${git_url##*/}
    local_dir=${PROJECT_DIR}/${local_dir%%.*}
    git clone ${git_url} ${local_dir}

    cd ${local_dir}
    mvn clean package
    ${tomcat_home}/bin/shutdown.sh
    sleep 2
    package=$(ls ${local_dir}/target/*.war)
    package=${package##*/}
    package=${package%%.*}
    cp ${local_dir}/target/*.war ${tomcat_home}/webapps/
    ${tomcat_home}/bin/startup.sh
    sleep 10
    service_manager_page="$(wget -qO- http://localhost:8080/${package}/services)"
    if [[ ${service_manager_page} == *Services* ]]; then
      echo "Deploy works !"
    else
      echo "Deploy DOES NOT work !"
    fi
}

cd ${LREC_DIR}
echo ""
echo "http://localhost:8080/service_manager"
echo ""


echo ""
echo "Prepare \"Project\" directory ..."
echo ""
if [[ -d "${PROJECT_DIR}" ]]; then
echo "${PROJECT_DIR} already exists ."
else
mkdir "${PROJECT_DIR}"
fi


cd "${PROJECT_DIR}"

cd "${PROJECT_DIR}"


#echo ""
#echo "Install python ..."
#echo ""
#if [[ -z $(which python) ]]; then
#echo "${USER_PASSWD}" | sudo -S apt-get --yes --force-yes install python
#fi

echo ""
echo "Deploy Services ..."
echo "------------- Deploy ---------------------"
echo ""

deploy_git_2_tomcat "${WS_GIT_HUB}" "${TOMCAT6_HOME}"


echo
echo "Running Git ..."
echo "<------------ Git Clone ------------------"
git clone ${LDDL_GIT_HUB} ${PROJECT_DIR}/lddl
${PROJECT_DIR}/lddl/bin/lddl.sh ${PROJECT_DIR}/lddl/src/lddl-scripts/LREC.lddl clean

