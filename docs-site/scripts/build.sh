antora --fetch antora-playbook.yml --stacktrace
rm ../static/documentation/*.html
rm ../static/documentation/operator/*.html
cp -r build/site/artemiscloud-docs/dev/* ../static/documentation/
cp -r build/site/_/css ../static/