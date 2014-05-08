#!/bin/bash

UBUNTU_DIR=$(pwd)
PROJECT_DIR="$HOME/Project"

TOMCAT6_URL="http://mirror.nexcess.net/apache/tomcat/tomcat-6/v6.0.39/bin/apache-tomcat-6.0.39.tar.gz"
TOMCAT6_TAR="$PROJECT_DIR/tomcat6.tar.gz"
TOMCAT6_HOME="$PROJECT_DIR/apache-tomcat-6.0.39/"
TOMCAT6_WEBAPP="${TOMCAT6_HOME}/webapps"

USER_PASSWD="lappsgrid"

POSTGRESQL_ROLE="langrid"
POSTGRESQL_PASSWD="langrid"
POSTGRESQL_DB="langrid"

SERVICEGRID_DOWNLOAD="http://eldrad.cs-i.brandeis.edu:8080/download/servicegrid/"
SERVICEGRID_CORENODE="langrid-corenode-p2p-2.0.0-20120718-modified.zip"
SERVICEGRID_SERVICEMANAGER="service_manager.war"

MAVEN_SETTING_URL="http://eldrad.cs-i.brandeis.edu:8080/download/settings.xml"

function __ubuntu_log {
     # echo "$(date '+%Y-%m-%d %H:%M:%S') (${3}) : ${1} = ${2} "
     echo "$(date '+%Y-%m-%d %H:%M:%S') (${3}) : ${1} = ${2} "   >>  "${UBUNTU_DIR}/lapps-ubuntu.log"
}



echo ""
echo "********** Repository **********"
echo ""
echo "${USER_PASSWD}" | sudo -S  apt-get update

echo ""
echo "Install git, maven2, unzip, java(jdk1.6) ..."
echo ""
if [[ -z $(which git) ]]; then
echo "${USER_PASSWD}" | sudo -S  apt-get --yes --force-yes install git
fi

if [[ -z $(which unzip) ]]; then
echo "${USER_PASSWD}" | sudo -S  apt-get --yes --force-yes install unzip
fi

if [[ -z $(which java) ]]; then
echo "${USER_PASSWD}" | sudo -S  apt-get --yes --force-yes install default-jdk
fi

if [[ -z $(which mvn) ]]; then
echo "${USER_PASSWD}" | sudo -S  apt-get --yes --force-yes install maven2
fi

if [[ -d $HOME/.m2 ]]; then
echo ""
else
mkdir $HOME/.m2
fi
wget ${MAVEN_SETTING_URL} -O $HOME/.m2/settings.xml

if [[ -d $HOME/.m2/settings.xml ]]; then
echo ""
else
echo "Maven setting NOT works !"
fi

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
echo "********** Tomcat6 **********"
echo ""

echo ""
echo "Install Tomcat6 to Project ..."
echo ""


if [[ -d "${TOMCAT6_HOME}" ]]; then
echo "${TOMCAT6_HOME} already exists ."
else
wget "$TOMCAT6_URL" -O "$TOMCAT6_TAR"
tar -zxvf "$TOMCAT6_TAR"
fi


echo ""
echo "Test Tomcat6 ..."
echo ""
cd "$TOMCAT6_HOME"
"$TOMCAT6_HOME/bin/startup.sh"
sleep 1
tomcat_home_page="$(wget -qO- http://localhost:8080)"
if [[ $tomcat_home_page == *Apache* ]]; then
  echo "Tomcat6 works !"
else
  echo "Tomcat6 DOES NOT work !"
fi
tomcat_shutdown=$("${TOMCAT6_HOME}"/bin/shutdown.sh)
sleep 2

echo ""
echo "********** PostgreSQL9 **********"
echo ""
if [[ -z $(which psql) ]]; then
echo ""
echo "Install PostgreSQL9.1 ..."
echo ""
echo "${USER_PASSWD}" | sudo -S  apt-get --yes --force-yes install postgresql postgresql-contrib
else
echo ""
echo "PostgreSQL installled ."
echo ""
fi

# sudo nano /etc/postgresql/9.3/main/pg_hba.conf
# echo "# Database administrative login by Unix domain socket:"
# echo "local   all             postgres                                md5"

echo ""
echo "Test PostgreSQL ..."
echo ""
postgres_create_db_template1=$(echo "${USER_PASSWD}" | sudo -S -u postgres createdb template1)
if [[ ${postgres_create_db_template1} == *already* ]]; then
  echo "PostgreSQL works !"
else
  echo "PostgreSQL DOES NOT work !"
fi

echo ""
echo "Create ROLE(${POSTGRESQL_ROLE}) DB(${POSTGRESQL_DB}) ..."
echo ""
#postgres_create_role_lapps=$(sudo -u postgres psql -c "create role ${POSTGRESQL_ROLE} with createdb login password '${POSTGRESQL_PASSWD}';")
#if [[ ${postgres_create_db_template1} == *ROLE* ]]; then
#  echo "Create ROLE=${POSTGRESQL_ROLE} works !"
#else
#  echo "Create ROLE=${POSTGRESQL_ROLE} DOES NOT work !"
#fi
#
#postgres_createdb_lappsdb=$(createdb -U ${POSTGRESQL_ROLE} ${POSTGRESQL_DB})
#
#if [[ -z ${postgres_createdb_lappsdb} ]]; then
#  echo "Create DB=${POSTGRESQL_DB} works !"
#else
#  echo "Create DB=${POSTGRESQL_DB} DOES NOT work !"
#fi
if [[ -f "${PROJECT_DIR}/${SERVICEGRID_CORENODE}" ]]; then
echo ""
else
wget "${SERVICEGRID_DOWNLOAD}${SERVICEGRID_CORENODE}" -O "${PROJECT_DIR}/${SERVICEGRID_CORENODE}"
fi

if [[ -d "${PROJECT_DIR}/corenode" ]]; then
rm -rf "${PROJECT_DIR}/corenode"
fi

unzip "${PROJECT_DIR}/${SERVICEGRID_CORENODE}" -d "${PROJECT_DIR}/corenode"
create_storedproc="${PROJECT_DIR}/corenode/postgresql/create_storedproc.sql"

#echo "${USER_PASSWD}" | sudo -S -u postgres createuser -S -D -R -P ${POSTGRESQL_ROLE}
## http://www.postgresql.org/docs/8.1/static/sql-createrole.html
## http://www.postgresql.org/docs/9.2/static/app-createuser.html
postgres_create_role_lapps=$(echo "${USER_PASSWD}" | sudo -S -u postgres psql -c "create role ${POSTGRESQL_ROLE} with NOSUPERUSER NOCREATEDB NOCREATEROLE login password '${POSTGRESQL_PASSWD}';")
if [[ ${postgres_create_db_template1} == *ROLE* ]]; then
  echo "Create ROLE=${POSTGRESQL_ROLE} works !"
else
  echo "Create ROLE=${POSTGRESQL_ROLE} DOES NOT work !"
fi
echo "${USER_PASSWD}" | sudo -S -u postgres createdb ${POSTGRESQL_DB} -O ${POSTGRESQL_ROLE} -E 'UTF8'
echo "${USER_PASSWD}" | sudo -S -u postgres createlang plpgsql ${POSTGRESQL_DB}
echo "${USER_PASSWD}" | sudo -S -u postgres psql ${POSTGRESQL_DB} < ${create_storedproc}
echo "${USER_PASSWD}" | sudo -S -u postgres psql ${POSTGRESQL_DB} -c "ALTER FUNCTION \"AccessStat.increment\"(character varying, character varying, character varying, character varying, character varying, timestamp without time zone, timestamp without time zone, integer, timestamp without time zone, integer, timestamp without time zone, integer, integer, integer, integer) OWNER TO $ROLENAME"


service_manager_war="${TOMCAT6_HOME}/webapps/service_manager.war"


###  stop tomcat
##
#
cd "$TOMCAT6_HOME"
if [[ $("$TOMCAT6_HOME"/bin/shutdown.sh) == *refused* ]]; then
echo "Tomcat6 restart ..."
else
echo "Tomcat6 restart ERROR !"
fi
sleep 2

if [[ -f ${service_manager_war} ]]; then
echo ""
else
echo "Download Service Manager War ..."
wget "${SERVICEGRID_DOWNLOAD}${SERVICEGRID_SERVICEMANAGER}" -O "${TOMCAT6_HOME}/webapps/service_manager.war"
fi


###  restart tomcat
##
#
"$TOMCAT6_HOME/bin/startup.sh"
sleep 6
tomcat_shutdown=$("$TOMCAT6_HOME/bin/shutdown.sh")
sleep 2



tomcat_langrid="${PROJECT_DIR}/corenode/tomcat-langrid"

#LANGRID_CONF=$(cat<<END_OF_LANGRID_CONF #END_OF_LANGRID_CONF)
LANGRID_CONF="<?xml version='1.0' encoding='utf-8'?>
<Context
	reloadable='true'
	displayName='Language Grid Core Node'
	>
	<Resource
		name='jdbc/langrid' auth='Container' type='javax.sql.DataSource'
		maxActive='100' maxIdle='50' maxWait='10000'
		username='${POSTGRESQL_ROLE}' password='${POSTGRESQL_PASSWD}'
		driverClassName='org.postgresql.Driver'
		url='jdbc:postgresql:${POSTGRESQL_DB}'
	/>
	<Parameter
		name='langrid.activeBpelServicesUrl'
		value='http://eldrad.cs-i.brandeis.edu:8081/active-bpel/services'
	/>
	<Parameter
		name='langrid.maxCallNest'
		value='16'
	/>

	<Parameter name='langrid.node.gridId' value='lapps_grid_1' />
	<Parameter name='langrid.node.nodeId' value='lapps_node_1' />
	<Parameter name='langrid.node.name' value='lapps ubuntu' />
	<Parameter name='langrid.node.url' value='http://127.0.0.1:8080/service_manager/' />
	<Parameter name='langrid.node.os' value='Ubuntu 12.10' />
	<Parameter name='langrid.node.cpu' value='Intel(R) Xeon(R) CPU E5-4620 0 @ 2.20GHz' />
	<Parameter name='langrid.node.memory' value='121 G' />
	<Parameter name='langrid.node.specialNotes' value='Mannual Installation' />

	<Parameter name='langrid.operator.userId' value='lapps' />
	<Parameter name='langrid.operator.initialPassword' value='lappsgrid' />
	<Parameter name='langrid.operator.organization' value='lapps provider' />
	<Parameter name='langrid.operator.responsiblePerson' value='lapps provider' />
	<Parameter name='langrid.operator.emailAddress' value='lapps@' />
	<Parameter name='langrid.operator.homepageUrl' value='http://' />
	<Parameter name='langrid.operator.address' value='USA' />

	<Parameter name='langrid.serviceManagerCopyright' value='Copyright 2014' />

	<Parameter name='langrid.activeBpelServicesUrl' value='' />
	<Parameter name='langrid.activeBpelAppAuthKey' value='' />

	<Parameter name='langrid.atomicServiceReadTimeout' value='30000' />
	<Parameter name='langrid.compositeServiceReadTimeout' value='30000' />
	<Parameter name='langrid.maxCallNest' value='16' />

	<Parameter name='appAuth.simpleApp.authIps' value='127.0.0.1' />
	<Parameter name='appAuth.simpleApp.authKey' value='eldrad' />
</Context>
"



echo "CATALINA_OPTS=\"-Xmx512m -XX:PermSize=128m -XX:MaxPermSize=256m -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/tmp\"" > "${TOMCAT6_HOME}/bin/setenv.sh"

echo ""
echo "Configure Service Manager in Tomcat6 ..."
echo ""
echo "${LANGRID_CONF}" > ${TOMCAT6_HOME}/conf/Catalina/localhost/service_manager.xml
cp ${tomcat_langrid}/lib/*.jar ${TOMCAT6_HOME}/lib/

tomcat_shutdown=$("$TOMCAT6_HOME/bin/shutdown.sh")
sleep 2
"$TOMCAT6_HOME/bin/startup.sh"

sleep 8
service_manager_page="$(wget -qO- http://localhost:8080/service_manager)"
if [[ ${service_manager_page} == *lapps_grid_1* ]]; then
  echo "Service Manager works !"
else
  echo "Service Manager DOES NOT work !"
fi

cd ${UBUNTU_DIR}
echo ""
echo "http://localhost:8080/service_manager"
echo ""
