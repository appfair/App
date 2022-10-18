#!/bin/sh -e

PACKAGE=App
FILE=stations

# see: https://api.radio-browser.info
#curl -fsSL https://nl1.api.radio-browser.info/csv/stations/search > Sources/App/Resources/stations.csv

sqlite3 "Sources/${PACKAGE}/Resources/${FILE}.db" << EOF
DROP TABLE IF EXISTS stations;

CREATE TABLE IF NOT EXISTS "stations"(
    "changeuuid" TEXT,
    "stationuuid" TEXT,
    "serveruuid" TEXT,
    "name" TEXT,
    "url" TEXT,
    "url_resolved" TEXT,
    "homepage" TEXT,
    "favicon" TEXT,
    "tags" TEXT,
    "country" TEXT,
    "countrycode" TEXT,
    "iso_3166_2" TEXT,
    "state" TEXT,
    "language" TEXT,
    "languagecodes" TEXT,
    "votes" TEXT,
    "lastchangetime" TEXT,
    "lastchangetime_iso8601" TEXT,
    "codec" TEXT,
    "bitrate" TEXT,
    "hls" TEXT,
    "lastcheckok" TEXT,
    "lastchecktime" TEXT,
    "lastchecktime_iso8601" TEXT,
    "lastcheckoktime" TEXT,
    "lastcheckoktime_iso8601" TEXT,
    "lastlocalchecktime" TEXT,
    "lastlocalchecktime_iso8601" TEXT,
    "clicktimestamp" TEXT,
    "clicktimestamp_iso8601" TEXT,
    "clickcount" INT,
    "clicktrend" INT,
    "ssl_error" INT,
    "geo_lat" TEXT,
    "geo_long" TEXT,
    "has_extended_info" TEXT)
    STRICT;

.import --skip 1 --csv Sources/App/Resources/stations.csv stations

ALTER TABLE "stations" DROP COLUMN "country";
ALTER TABLE "stations" DROP COLUMN "lastcheckok";
ALTER TABLE "stations" DROP COLUMN "lastchecktime";
ALTER TABLE "stations" DROP COLUMN "lastchecktime_iso8601";
ALTER TABLE "stations" DROP COLUMN "lastcheckoktime";
ALTER TABLE "stations" DROP COLUMN "lastcheckoktime_iso8601";
ALTER TABLE "stations" DROP COLUMN "lastlocalchecktime";
ALTER TABLE "stations" DROP COLUMN "lastlocalchecktime_iso8601";
ALTER TABLE "stations" DROP COLUMN "clicktimestamp";
ALTER TABLE "stations" DROP COLUMN "clicktimestamp_iso8601";

CREATE INDEX stations_name ON stations(name);
CREATE INDEX stations_tags ON stations(tags);
CREATE INDEX stations_countrycode ON stations(countrycode);
CREATE INDEX stations_languagecodes ON stations(languagecodes);

VACUUM;

select count(*) from stations;
EOF

ls -lah "Sources/${PACKAGE}/Resources/${FILE}.db"
shasum -a 256 "Sources/${PACKAGE}/Resources/${FILE}.db"

