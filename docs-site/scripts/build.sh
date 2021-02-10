cd ../../antora-ui-default/
gulp bundle;  cp build/ui-bundle.zip ../website/docs-site/
cd ../website/docs-site
antora --fetch antora-playbook.yml --stacktrace
rm ../static/docs/*.html
rm ../static/docs/broker-ocp/*.html
cp -r build/site/artemiscloud-docs/dev/* ../static/docs/
cp -r build/site/_/css ../static/