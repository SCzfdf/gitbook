#!/bin/bash
tmp=`ps -ef | grep 'gitbook serve'| grep -v grep | awk '{print $2}'`
echo ${tmp}
kill -9 ${tmp}

java -jar gitbook_summary_init.jar

gitbook install

daemonize -E BUILD_ID=dontKillMe  -c /home/jenkins/.jenkins/workspace/gitbook/gitbook /usr/lib/node_modules/gitbook-cli/bin/gitbook.js serve --port 4000 --lrport 35730