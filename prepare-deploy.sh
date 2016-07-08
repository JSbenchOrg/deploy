#!/usr/bin/env bash
DIR=$PWD
source .env

cd $DIR/tmp/server
#git fetch
#git pull -s recursive -X theirs
export WWW_COMMITID=$(git rev-parse --short HEAD)

cd $DIR/tmp/server
#git fetch
#git pull -s recursive -X theirs
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
# todo search and replace config URL in app.js
ncftpput -R -v -u "$LOGIN" -p "$PASSWORD" $REMOTESERVER www "$DIR/tmp/release/$WWW_VERSION"
rm -rf $DIR/tmp/release

mkdir $DIR/tmp/release
cp -r $DIR/tmp/server/ $DIR/tmp/release/
mv $DIR/tmp/release/server/ $DIR/tmp/release/$API_VERSION/
rm -rf $DIR/tmp/release/$API_VERSION/.git
rm -rf $DIR/tmp/release/$API_VERSION/tests
rm -rf $DIR/tmp/release/$API_VERSION/extra
# todo prepare config credentials
# todo prepare migration (clean / inject script)
ncftpput -R -v -u "$LOGIN" -p "$PASSWORD" $REMOTESERVER api "$DIR/tmp/release/$API_VERSION"
# todo make curl call to the migration script
rm -rf $DIR/tmp/release
