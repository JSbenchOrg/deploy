#!/usr/bin/env bash
# store current dir
DIR=$PWD
TMP_PATH=$DIR/tmp
CLIENT_REPO_PATH=$TMP_PATH/client
SERVER_REPO_PATH=$TMP_PATH/server

if [ -d "$TMP_PATH"  ]; then
    rm -rf $TMP_PATH
fi
mkdir $TMP_PATH

# load env variables
if [ -f .env ]; then
    source .env
    echo "Loaded local env settings"
fi

if [ -d "$CLIENT_REPO_PATH" ]; then
    git --git-dir=$CLIENT_REPO_PATH/.git fetch
    git --git-dir=$CLIENT_REPO_PATH/.git pull -s recursive -X theirs
    echo "Refreshed $CLIENT_REPO_PATH"
else
    git clone https://github.com/bogdananton/client --branch v3 $CLIENT_REPO_PATH # todo replace repo
    echo "Cloned into $CLIENT_REPO_PATH"
fi

if [ -d "$SERVER_REPO_PATH" ]; then
    git --git-dir=$SERVER_REPO_PATH/.git fetch
    git --git-dir=$SERVER_REPO_PATH/.git pull -s recursive -X theirs
    echo "Refreshed $SERVER_REPO_PATH"
else
    git clone https://github.com/JSBenchOrg/server $SERVER_REPO_PATH
    echo "Cloned into $SERVER_REPO_PATH"
fi

echo "Reload client repo"
cd $DIR/tmp/client
export WWW_COMMITID=$(git rev-parse --short HEAD)

# get components versions / commit IDs
export WWW_FULL_VERSION=$(cat $DIR/tmp/client/VERSION)
export WWW_VERSION=$(cat $DIR/tmp/client/VERSION | grep -Eo "v[[:digit:]].[[:digit:]]")
echo "Client-side-$WWW_VERSION has commit ID $WWW_COMMITID. Full version: $WWW_FULL_VERSION"

echo "Reload server repo"
cd $DIR/tmp/server
git fetch
git pull -s recursive -X theirs
export API_COMMITID=$(git rev-parse --short HEAD)
cd $DIR

# get components versions / commit IDs
export API_FULL_VERSION=$(cat $DIR/tmp/server/VERSION)
export API_VERSION=$(cat $DIR/tmp/server/VERSION | grep -Eo "v[[:digit:]].[[:digit:]]")
echo "Server-side-$API_FULL_VERSION has commit ID $API_COMMITID. Full version: $API_FULL_VERSION"

# clean working dir
rm -rf $DIR/tmp/release
mkdir $DIR/tmp/release
echo "Cleanup"

# copy to a dirty dir
cp -r $DIR/tmp/client/ $DIR/tmp/release/
echo "Copied the client to a tmp/release folder."

# replace target in pre-compiled files
sed -i "s/let serverUri \=/let serverUri \= \"https\:\/\/$DOMAIN_API\/$API_VERSION\"\;\/\//g" $DIR/tmp/release/client/ts/index.ts
sed -i "s/let clientUri \=/let clientUri \= \"https\:\/\/$DOMAIN_WWW\"\;\/\//g" $DIR/tmp/release/client/ts/index.ts
sed -i "s/http\:\/\/jsbench\.org/https\:\/\/$DOMAIN_WWW/g" $DIR/tmp/release/client/public/.htaccess
sed -i "s/www\\\.jsbench\\\.org/www\.$DOMAIN_WWW/g" $DIR/tmp/release/client/public/.htaccess
sed -i "s/jsbench\\\.org/$DOMAIN_WWW/g" $DIR/tmp/release/client/public/.htaccess
sed -i "s/<sup>v2\.5\.0<\/sup>/<sup>$WWW_VERSION<\/sup>/g" $DIR/tmp/release/client/public/index.html
echo "Applied client config settings."

## replace target in pre-compiled files (using a version folder)
#sed -i "s/let serverUri \=/let serverUri \= \"https\:\/\/$DOMAIN_API\/$API_VERSION\"\;\/\//g" $DIR/tmp/release/client/ts/index.ts
#sed -i "s/\.addRoute\(\'\//\.addRoute\(\'\/$API_VERSION\//g" $DIR/tmp/release/client/ts/App.ts
#sed -i "s/let clientUri \=/let clientUri \= \"https\:\/\/$DOMAIN_WWW\/$WWW_VERSION\"\;\/\//g" $DIR/tmp/release/client/ts/index.ts
#sed -i "s/href\=\"\//href\=\"\/$WWW_VERSION\//g" $DIR/tmp/release/client/public/index.html
#sed -i "s/src\=\"\//src\=\"\/$WWW_VERSION\//g" $DIR/tmp/release/client/public/index.html
#echo "Applied client config settings using a version folder."

# transpile TS -> JS
cd $DIR/tmp/release/client
npm install
npm install -g gulp
gulp tsc
cd $DIR

# keep only the public folder as the www folder and upload
echo "Moved public client folder to www folder."
mv $DIR/tmp/release/client/public $DIR/tmp/release/www
ncftpput -R -v -u "$LOGIN" -p "$PASSWORD" $REMOTESERVER . "$DIR/tmp/release/www"

# keep only the public folder as the version folder and upload
#echo "Moved public client folder to $WWW_VERSION folder."
#mv $DIR/tmp/release/client/public $DIR/tmp/release/$WWW_VERSION
#ncftpput -R -v -u "$LOGIN" -p "$PASSWORD" $REMOTESERVER www "$DIR/tmp/release/$WWW_VERSION"

# cleanup
rm -rf $DIR/tmp/release
mkdir $DIR/tmp/release

# clone and clean the server folder
cp -r $DIR/tmp/server/ $DIR/tmp/release/
mv $DIR/tmp/release/server/ $DIR/tmp/release/$API_VERSION/
rm -rf $DIR/tmp/release/$API_VERSION/.git
rm -rf $DIR/tmp/release/$API_VERSION/tests
rm -rf $DIR/tmp/release/$API_VERSION/deps/flight/tests
rm -rf $DIR/tmp/release/$API_VERSION/extra

# replace target in config file
cp $DIR/tmp/release/$API_VERSION/config.dist.php $DIR/tmp/release/$API_VERSION/config.php
sed -i "s/RewriteBase \//RewriteBase \/$API_VERSION\//g" $DIR/tmp/release/$API_VERSION/.htaccess
sed -i "s/\/index.php/\/$API_VERSION\/index.php/g" $DIR/tmp/release/$API_VERSION/.htaccess
sed -i "s/http\:\/\/jsbench.org/https\:\/\/$DOMAIN_WWW/g" $DIR/tmp/release/$API_VERSION/.htaccess
sed -i "s/PLACEHOLDER_ORIGIN/https\:\/\/$DOMAIN_WWW/g" $DIR/tmp/release/$API_VERSION/config.php
sed -i "s/BASE_URL/https\:\/\/$DOMAIN_API\/$API_VERSION/g" $DIR/tmp/release/$API_VERSION/config.php
sed -i "s/MYSQL_HOST/$MYSQL_HOST/g" $DIR/tmp/release/$API_VERSION/config.php
sed -i "s/MYSQL_DATABASE/$MYSQL_DATABASE/g" $DIR/tmp/release/$API_VERSION/config.php
sed -i "s/MYSQL_USER/$MYSQL_USER/g" $DIR/tmp/release/$API_VERSION/config.php
sed -i "s/MYSQL_PASSWORD/$MYSQL_PASSWORD/g" $DIR/tmp/release/$API_VERSION/config.php

# upload versioned folder
ncftpput -R -v -u "$LOGIN" -p "$PASSWORD" $REMOTESERVER api "$DIR/tmp/release/$API_VERSION"
curl https://$DOMAIN_API/$API_VERSION/migrate.php
rm -rf $DIR/tmp/release

# signal a successful staging
curl -H "Content-type: application/json" -H "Accept: application/json" -X POST -d "{\"body\": \"Pushed Client $WWW_VERSION and Server $API_VERSION to https://$DOMAIN_WWW and https://$DOMAIN_API/$API_VERSION\"}"  https://api.github.com/repos/JSbenchOrg/deploy/issues/3/comments?access_token=$ACCESS_TOKEN
