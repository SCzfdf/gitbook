java -jar gitbook_summary_init.jar

:: lrport监听器端口,默认35729 莫名其妙会被占用
gitbook serve --port 4000 --lrport 35730 --no-watch --no-live

pause