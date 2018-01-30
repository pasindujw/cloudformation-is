#!/usr/bin/env bash
# ----------------------------------------------------------------------------
#
# Copyright (c) 2017, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
#
# WSO2 Inc. licenses this file to you under the Apache License,
# Version 2.0 (the "License"); you may not use this file except
# in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
#
# ----------------------------------------------------------------------------

exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

set -e

echo ">> Downloading JDK: jdk-8u131-linux-x64"
wget --tries=3 --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/8u131-b11/d54c1d3a095b4ff2b6607d096fa80163/jdk-8u131-linux-x64.tar.gz -P downloads/jdk
echo ">> JDK download completed!"

echo ">> Downloading JDBC Driver: mysql-connector-java-5.1.41"
wget --tries=3 http://central.maven.org/maven2/mysql/mysql-connector-java/5.1.44/mysql-connector-java-5.1.44.jar -P downloads/jdbc
echo ">> JDBC Driver download completed!"

echo ">> Downloading WSO2 IS Distribution: wso2is-5.4.0-beta"
wget --tries=3 https://github.com/wso2/product-is/archive/v5.4.0-update6.zip -P downloads
echo ">> WSO2 IS download completed!"


