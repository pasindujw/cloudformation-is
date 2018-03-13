#!/usr/bin/env bash
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
# Echoes all commands before executing.
set -o verbose

readonly USERNAME=$2
readonly DB_HOST=$4
readonly DB_PORT=$6
readonly DB_ENGINE=$(echo "$8" | awk '{print tolower($0)}')
readonly DB_VERSION=$10
readonly IS_HOST_NAME=$12

readonly PRODUCT_NAME="wso2is"
readonly PRODUCT_VERSION="5.4.0"
readonly WUM_PRODUCT_NAME=${PRODUCT_NAME}-${PRODUCT_VERSION}
readonly WUM_PRODUCT_DIR=/home/${USERNAME}/.wum-wso2/products/${PRODUCT_NAME}/${PRODUCT_VERSION}
readonly INSTALLATION_DIR=/opt/wso2
readonly PRODUCT_HOME="${INSTALLATION_DIR}/${PRODUCT_NAME}-${PRODUCT_VERSION}"
readonly DB_SCRIPT_HOME="${PRODUCT_HOME}/dbscripts"

#Master DB connection details
readonly MASTER_DB_USERNAME="wso2"
readonly MASTER_DB_PASSWORD="password"

#MySQL connection details
readonly MYSQL_USERNAME=$MASTER_DB_USERNAME
readonly MYSQL_PASSWORD=$MASTER_DB_PASSWORD

#PostgreSQL connection details
readonly POSTGRES_USERNAME=$MASTER_DB_USERNAME
readonly POSTGRES_PASSWORD=$MASTER_DB_PASSWORD
readonly POSTGRES_DB="wso2db"

# databases
readonly UM_DB="wso2_um_db"
readonly IDENTITY_DB="wso2_identity_db"
readonly GOV_REG_DB="wso2_greg_db"
readonly BPS_DB="wso2_bps_db"
readonly METRICS_DB="wso2_metrics_db"

# database users
readonly UM_USER=$MASTER_DB_USERNAME
readonly UM_USER_PWD=$MASTER_DB_PASSWORD
readonly IDENTITY_USER=$MASTER_DB_USERNAME
readonly IDENTITY_USER_PWD=$MASTER_DB_PASSWORD
readonly GOV_REG_USER=$MASTER_DB_USERNAME
readonly GOV_REG_USER_PWD=$MASTER_DB_PASSWORD
readonly BPS_USER=$MASTER_DB_USERNAME
readonly BPS_USER_PWD=$MASTER_DB_PASSWORD
readonly METRICS_USER=$MASTER_DB_USERNAME
readonly METRICS_USER_PWD=$MASTER_DB_PASSWORD

setup_wum_updated_pack() {

    sudo -u ${USERNAME} /usr/local/wum/bin/wum add ${WUM_PRODUCT_NAME} -y
    sudo -u ${USERNAME} /usr/local/wum/bin/wum update ${WUM_PRODUCT_NAME}

    mkdir -p ${INSTALLATION_DIR}
    chown -R ${USERNAME} ${INSTALLATION_DIR}
    echo ">> Copying WUM updated ${WUM_PRODUCT_NAME} to ${INSTALLATION_DIR}"
    sudo -u ${USERNAME} unzip ${WUM_PRODUCT_DIR}/$(ls -t ${WUM_PRODUCT_DIR} | grep .zip | head -1) -d ${INSTALLATION_DIR}
}

setup_mysql_databases() {
    echo "MySQL setting up" >> /home/ubuntu/java.txt
    echo ">> Creating databases..."
    mysql -h $DB_HOST -P $DB_PORT -u $MYSQL_USERNAME -p$MYSQL_PASSWORD -e "DROP DATABASE IF EXISTS $UM_DB; DROP DATABASE IF
    EXISTS $IDENTITY_DB; DROP DATABASE IF EXISTS $GOV_REG_DB; DROP DATABASE IF EXISTS $BPS_DB; DROP DATABASE IF EXISTS $METRICS_DB;
     CREATE DATABASE $UM_DB; CREATE DATABASE $IDENTITY_DB; CREATE DATABASE $GOV_REG_DB; CREATE DATABASE $BPS_DB; CREATE DATABASE $METRICS_DB;"
    echo ">> Databases created!"

    echo ">> Creating users..."
    mysql -h $DB_HOST -P $DB_PORT -u $MYSQL_USERNAME -p$MYSQL_PASSWORD -e "CREATE USER '$UM_USER'@'%' IDENTIFIED BY
    '$UM_USER_PWD'; CREATE USER '$IDENTITY_USER'@'%' IDENTIFIED BY '$IDENTITY_USER_PWD'; CREATE USER '$GOV_REG_USER'@'%'
    IDENTIFIED BY '$GOV_REG_USER_PWD'; CREATE USER '$BPS_USER'@'%' IDENTIFIED BY '$BPS_USER_PWD';
    CREATE USER '$METRICS_USER'@'%' IDENTIFIED BY '$METRICS_USER_PWD';"
    echo ">> Users created!"

    echo -e ">> Grant access for users..."
    mysql -h $DB_HOST -P $DB_PORT -u $MYSQL_USERNAME -p$MYSQL_PASSWORD -e "GRANT ALL PRIVILEGES ON $UM_DB.* TO '$UM_USER'@'%';
    GRANT ALL PRIVILEGES ON $IDENTITY_DB.* TO '$IDENTITY_USER'@'%'; GRANT ALL PRIVILEGES ON $GOV_REG_DB.* TO
    '$GOV_REG_USER'@'%'; GRANT ALL PRIVILEGES ON $BPS_DB.* TO '$BPS_USER'@'%'; 
    GRANT ALL PRIVILEGES ON $METRICS_DB.* TO '$METRICS_USER'@'%';"
    echo ">> Access granted!"

    echo ">> Creating tables..."
    if [ $DB_VERSION -ge  5.7.0]; then
    	mysql -h $DB_HOST -P $DB_PORT -u $MYSQL_USERNAME -p$MYSQL_PASSWORD -e "USE $UM_DB; SOURCE $DB_SCRIPT_HOME/mysql5.7.sql;
	USE $GOV_REG_DB; SOURCE $DB_SCRIPT_HOME/mysql5.7.sql; USE $IDENTITY_DB; SOURCE $DB_SCRIPT_HOME/identity/mysql-5.7.sql;
	USE $BPS_DB; SOURCE $DB_SCRIPT_HOME/bps/bpel/create/mysql.sql; USE $METRICS_DB; 
	SOURCE $DB_SCRIPT_HOME/metrics/mysql.sql;"
    else
    	mysql -h $DB_HOST -P $DB_PORT -u $MYSQL_USERNAME -p$MYSQL_PASSWORD -e "USE $UM_DB; SOURCE $DB_SCRIPT_HOME/mysql.sql;
	USE $GOV_REG_DB; SOURCE $DB_SCRIPT_HOME/mysql.sql; USE $IDENTITY_DB; SOURCE $DB_SCRIPT_HOME/identity/mysql.sql; 
	USE $BPS_DB; SOURCE $DB_SCRIPT_HOME/bps/bpel/create/mysql.sql; USE $METRICS_DB; 
	SOURCE $DB_SCRIPT_HOME/metrics/mysql.sql;"
    fi
    echo ">> Tables created!"
}

setup_postgres_databases() {
    echo "Postgres setting up" >> /home/ubuntu/java.txt
    export PGPASSWORD=$POSTGRES_PASSWORD

    echo ">> Creating users..."
    psql -h $DB_HOST -p $DB_PORT -U $POSTGRES_USERNAME -d $POSTGRES_DB -c "CREATE USER $UM_USER WITH LOGIN PASSWORD '$UM_USER_PWD';"
    psql -h $DB_HOST -p $DB_PORT -U $POSTGRES_USERNAME -d $POSTGRES_DB -c "CREATE USER $IDENTITY_USER WITH LOGIN PASSWORD '$IDENTITY_USER_PWD';"
    psql -h $DB_HOST -p $DB_PORT -U $POSTGRES_USERNAME -d $POSTGRES_DB -c "CREATE USER $GOV_REG_USER WITH LOGIN PASSWORD '$GOV_REG_USER_PWD';"
    psql -h $DB_HOST -p $DB_PORT -U $POSTGRES_USERNAME -d $POSTGRES_DB -c "CREATE USER $BPS_USER WITH LOGIN PASSWORD '$BPS_USER_PWD';"
    psql -h $DB_HOST -p $DB_PORT -U $POSTGRES_USERNAME -d $POSTGRES_DB -c "CREATE USER $METRICS_USER WITH LOGIN PASSWORD '$METRICS_USER_PWD';"
    echo ">> Users created!"

    echo -e ">> Create databases"
    psql -h $DB_HOST -p $DB_PORT -U $POSTGRES_USERNAME -d $POSTGRES_DB -c "CREATE DATABASE $UM_DB;"
    psql -h $DB_HOST -p $DB_PORT -U $POSTGRES_USERNAME -d $POSTGRES_DB -c "CREATE DATABASE $IDENTITY_DB;"
    psql -h $DB_HOST -p $DB_PORT -U $POSTGRES_USERNAME -d $POSTGRES_DB -c "CREATE DATABASE $GOV_REG_DB;"
    psql -h $DB_HOST -p $DB_PORT -U $POSTGRES_USERNAME -d $POSTGRES_DB -c "CREATE DATABASE $BPS_DB;"
    psql -h $DB_HOST -p $DB_PORT -U $POSTGRES_USERNAME -d $POSTGRES_DB -c "CREATE DATABASE $METRICS_DB;"

    echo -e ">> Grant access for users..."
    psql -h $DB_HOST -p $DB_PORT -U $POSTGRES_USERNAME -d $POSTGRES_DB -c "GRANT ALL PRIVILEGES ON DATABASE $UM_DB TO $UM_USER;"
    psql -h $DB_HOST -p $DB_PORT -U $POSTGRES_USERNAME -d $POSTGRES_DB -c "GRANT ALL PRIVILEGES ON DATABASE $IDENTITY_DB TO $IDENTITY_USER;"
    psql -h $DB_HOST -p $DB_PORT -U $POSTGRES_USERNAME -d $POSTGRES_DB -c "GRANT ALL PRIVILEGES ON DATABASE $GOV_REG_DB TO $GOV_REG_USER;"
    psql -h $DB_HOST -p $DB_PORT -U $POSTGRES_USERNAME -d $POSTGRES_DB -c "GRANT ALL PRIVILEGES ON DATABASE $BPS_DB TO $UM_USER;"
    psql -h $DB_HOST -p $DB_PORT -U $POSTGRES_USERNAME -d $POSTGRES_DB -c "GRANT ALL PRIVILEGES ON DATABASE $METRICS_DB TO $METRICS_USER;"
    echo ">> Access granted!"

    echo ">> Creating tables..."
    psql -h $DB_HOST -p $DB_PORT -U $POSTGRES_USERNAME -d $UM_DB -f $DB_SCRIPT_HOME/postgresql.sql
    psql -h $DB_HOST -p $DB_PORT -U $POSTGRES_USERNAME -d $GOV_REG_DB -f $DB_SCRIPT_HOME/postgresql.sql
    psql -h $DB_HOST -p $DB_PORT -U $POSTGRES_USERNAME -d $IDENTITY_DB -f $DB_SCRIPT_HOME/identity/postgresql.sql
    psql -h $DB_HOST -p $DB_PORT -U $POSTGRES_USERNAME -d $BPS_DB -f $DB_SCRIPT_HOME/bps/bpel/create/postgresql.sql
    psql -h $DB_HOST -p $DB_PORT -U $POSTGRES_USERNAME -d $METRICS_DB -f $DB_SCRIPT_HOME/metrics/postgresql.sql
    echo ">> Tables created!"
}

copy_libs() {

    echo ">> Copying $DB_ENGINE jdbc driver "
    cp /tmp/jdbc-connector.jar ${PRODUCT_HOME}/repository/components/lib
}

copy_config_files() {

    echo ">> Copying configuration files "
    cp -r -v product-configs/* ${PRODUCT_HOME}/repository/conf/
    echo ">> Done!"
}

configure_product() {
    DB_TYPE=$(get_jdbc_url_prefix)
    DRIVER_CLASS=$(get_driver_class)
    echo ">> Configuring product "
    find ${PRODUCT_HOME}/ -type f \( -iname "*.properties" -o -iname "*.xml" \) -print0 | xargs -0 sed -i 's/#_IS_LB_HOSTNAME_#/'$IS_HOST_NAME'/g'
    find ${PRODUCT_HOME}/ -type f \( -iname "*.properties" -o -iname "*.xml" \) -print0 | xargs -0 sed -i 's/#_RDS_HOSTNAME_#/'$DB_HOST'/g'
    find ${PRODUCT_HOME}/ -type f \( -iname "*.properties" -o -iname "*.xml" \) -print0 | xargs -0 sed -i 's/#_RDS_PORT_#/'$DB_PORT'/g'
    find ${PRODUCT_HOME}/ -type f \( -iname "*.properties" -o -iname "*.xml" \) -print0 | xargs -0 sed -i 's/#_RDS_TYPE_#/'$DB_TYPE'/g'
    find ${PRODUCT_HOME}/ -type f \( -iname "*.properties" -o -iname "*.xml" \) -print0 | xargs -0 sed -i 's/#_DRIVER_CLASS_#/'$DRIVER_CLASS'/g'
    find ${PRODUCT_HOME}/ -type f \( -iname "*.properties" -o -iname "*.xml" \) -print0 | xargs -0 sed -i 's/#_UM_DB_#/'$UM_DB'/g'
    find ${PRODUCT_HOME}/ -type f \( -iname "*.properties" -o -iname "*.xml" \) -print0 | xargs -0 sed -i 's/#_UM_USER_#/'$UM_USER'/g'
    find ${PRODUCT_HOME}/ -type f \( -iname "*.properties" -o -iname "*.xml" \) -print0 | xargs -0 sed -i 's/#_UM_USER_PWD_#/'$UM_USER_PWD'/g'
    find ${PRODUCT_HOME}/ -type f \( -iname "*.properties" -o -iname "*.xml" \) -print0 | xargs -0 sed -i 's/#_GOV_REG_DB_#/'$GOV_REG_DB'/g'
    find ${PRODUCT_HOME}/ -type f \( -iname "*.properties" -o -iname "*.xml" \) -print0 | xargs -0 sed -i 's/#_GOV_REG_USER_#/'$GOV_REG_USER'/g'
    find ${PRODUCT_HOME}/ -type f \( -iname "*.properties" -o -iname "*.xml" \) -print0 | xargs -0 sed -i 's/#_GOV_REG_USER_PWD_#/'$GOV_REG_USER_PWD'/g'
    find ${PRODUCT_HOME}/ -type f \( -iname "*.properties" -o -iname "*.xml" \) -print0 | xargs -0 sed -i 's/#_IDENTITY_DB_#/'$IDENTITY_DB'/g'
    find ${PRODUCT_HOME}/ -type f \( -iname "*.properties" -o -iname "*.xml" \) -print0 | xargs -0 sed -i 's/#_IDENTITY_USER_#/'$IDENTITY_USER'/g'
    find ${PRODUCT_HOME}/ -type f \( -iname "*.properties" -o -iname "*.xml" \) -print0 | xargs -0 sed -i 's/#_IDENTITY_USER_PWD_#/'$IDENTITY_USER_PWD'/g'
    find ${PRODUCT_HOME}/ -type f \( -iname "*.properties" -o -iname "*.xml" \) -print0 | xargs -0 sed -i 's/#_BPS_DB_#/'$BPS_DB'/g'
    find ${PRODUCT_HOME}/ -type f \( -iname "*.properties" -o -iname "*.xml" \) -print0 | xargs -0 sed -i 's/#_BPS_USER_#/'$BPS_USER'/g'
    find ${PRODUCT_HOME}/ -type f \( -iname "*.properties" -o -iname "*.xml" \) -print0 | xargs -0 sed -i 's/#_BPS_USER_PWD_#/'$BPS_USER_PWD'/g'
    echo "Done!"
}

get_driver_class() {
    DRIVER_CLASS=""
    if [ $DB_ENGINE = "postgres" ]; then
        DRIVER_CLASS="org.postgresql.Driver"
    elif [ $DB_ENGINE = "mysql" ]; then
	DRIVER_CLASS="com.mysql.jdbc.Driver"
    elif [ $DB_ENGINE = "oracle-se" ]; then
        DRIVER_CLASS="com.mysql.jdbc.Driver"
    elif [ $DB_ENGINE = "sqlserver-ex" ]; then
        DRIVER_CLASS="com.mysql.jdbc.Driver"
    elif [ $DB_ENGINE = "mariadb" ]; then
        DRIVER_CLASS="com.mysql.jdbc.Driver"
    fi
    echo $DRIVER_CLASS
}

get_jdbc_url_prefix() {
    URL=""
    if [ $DB_ENGINE = "postgres" ]; then
        URL="postgresql"
    elif [ $DB_ENGINE = "mysql" ]; then
	URL="mysql"
    elif [ $DB_ENGINE = "oracle-se" ]; then
        URL="oracle:thin"
    elif [ $DB_ENGINE = "sqlserver-ex" ]; then
        URL="sqlserver"
    elif [ $DB_ENGINE = "mariadb" ]; then
        URL="mariadb"
    fi
    echo $URL
}

start_product() {
    source /etc/environment
    echo ">> Starting WSO2 Identity Server ... "
    echo DB_ENGINE=${DB_ENGINE} >> /home/ubuntu/java.txt
    sudo -u ${USERNAME} bash ${PRODUCT_HOME}/bin/wso2server.sh start
}

main() {

    setup_wum_updated_pack
    if [ $DB_ENGINE = "postgres" ]; then
    	setup_postgres_databases
    elif [ $DB_ENGINE = "mysql" ]; then
    	setup_mysql_databases
    fi
    copy_libs
    copy_config_files
    configure_product
    start_product
}

main
