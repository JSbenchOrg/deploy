#!/usr/bin/env bash
DIR=$PWD
source .env

cd $DIR/tmp/server
git fetch
git pull -s recursive -X theirs
export WWW_COMMITID=$(git rev-parse --short HEAD)

cd $DIR/tmp/server
git fetch
git pull -s recursive -X theirs
export API_COMMITID=$(git rev-parse --short HEAD)
cd $DIR

export WWW_FULL_VERSION=$(cat $DIR/tmp/client/VERSION)
export API_FULL_VERSION=$(cat $DIR/tmp/server/VERSION)

export WWW_VERSION=$(cat $DIR/tmp/client/VERSION | grep -Eo "v[[:digit:]].[[:digit:]]")
export API_VERSION=$(cat $DIR/tmp/server/VERSION | grep -Eo "v[[:digit:]].[[:digit:]]")

echo "Client-side $WWW_FULL_VERSION with commit ID: $WWW_COMMITID"
echo "Server-side $API_FULL_VERSION with commit ID: $API_COMMITID"
rm -rf $DIR/tmp/release

mkdir $DIR/tmp/release
cp -r $DIR/tmp/client/ $DIR/tmp/release/
mv $DIR/tmp/release/client/ $DIR/tmp/release/$WWW_VERSION/
rm -rf $DIR/tmp/release/$WWW_VERSION/.git
sed -i 's/http\:\/\//https\:\/\//g' $DIR/tmp/release/$WWW_VERSION/js/app.js
sed -i "s/api\.jsbench\.org/api\.stage\.jsbench\.org\/$API_VERSION/g" $DIR/tmp/release/$WWW_VERSION/js/app.js
ncftpput -R -v -u "$LOGIN" -p "$PASSWORD" $REMOTESERVER www "$DIR/tmp/release/$WWW_VERSION"
rm -rf $DIR/tmp/release

mkdir $DIR/tmp/release
cp -r $DIR/tmp/server/ $DIR/tmp/release/
mv $DIR/tmp/release/server/ $DIR/tmp/release/$API_VERSION/
rm -rf $DIR/tmp/release/$API_VERSION/.git
rm -rf $DIR/tmp/release/$API_VERSION/tests
rm -rf $DIR/tmp/release/$API_VERSION/extra
cp $DIR/tmp/release/$API_VERSION/config.dist.php $DIR/tmp/release/$API_VERSION/config.php
sed -i "s/PLACEHOLDER_ORIGIN/https\:\/\/$DOMAIN_WWW/g" $DIR/tmp/release/$API_VERSION/config.php
sed -i "s/BASE_URL/https\:\/\/$DOMAIN_API\/$API_VERSION/g" $DIR/tmp/release/$API_VERSION/config.php
sed -i "s/MYSQL_HOST/$MYSQL_HOST/g" $DIR/tmp/release/$API_VERSION/config.php
sed -i "s/MYSQL_DATABASE/$MYSQL_DATABASE/g" $DIR/tmp/release/$API_VERSION/config.php
sed -i "s/MYSQL_USER/$MYSQL_USER/g" $DIR/tmp/release/$API_VERSION/config.php
sed -i "s/MYSQL_PASSWORD/$MYSQL_PASSWORD/g" $DIR/tmp/release/$API_VERSION/config.php
ncftpput -R -v -u "$LOGIN" -p "$PASSWORD" $REMOTESERVER api "$DIR/tmp/release/$API_VERSION"
# todo make curl call to the migration script
# curl https://$DOMAIN_API/$API_VERSION/install.php
rm -rf $DIR/tmp/release
