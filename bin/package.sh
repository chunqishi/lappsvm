#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd ${DIR}/../src/
zip ${DIR}/../lappsvm-install.zip *.sh
cd ${DIR}