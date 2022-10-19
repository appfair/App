#!/bin/sh -e

PACKAGE=App
FILE=stations

STATIONS=${TMPDIR}/stations.csv

# see: https://api.radio-browser.info
curl -fsSL https://nl1.api.radio-browser.info/csv/stations/search > ${STATIONS}

rm -vf "Sources/${PACKAGE}/Resources/${FILE}.db"

sqlite3 "Sources/${PACKAGE}/Resources/${FILE}.db" << EOF
DROP TABLE IF EXISTS station;

CREATE TABLE IF NOT EXISTS "station" (
    "changeuuid" TEXT,
    "stationuuid" TEXT PRIMARY KEY,
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
    "has_extended_info" TEXT);

    -- STRICT; -- needs more recent version of sqlite

.import --skip 1 --csv ${STATIONS} station

-- ALTER TABLE "station" DROP COLUMN "XXX";

ALTER TABLE "station" DROP COLUMN "country";
ALTER TABLE "station" DROP COLUMN "lastcheckok";
ALTER TABLE "station" DROP COLUMN "lastchecktime";
ALTER TABLE "station" DROP COLUMN "lastchecktime_iso8601";
ALTER TABLE "station" DROP COLUMN "lastcheckoktime";
ALTER TABLE "station" DROP COLUMN "lastcheckoktime_iso8601";
ALTER TABLE "station" DROP COLUMN "lastlocalchecktime";
ALTER TABLE "station" DROP COLUMN "lastlocalchecktime_iso8601";
ALTER TABLE "station" DROP COLUMN "clicktimestamp";
ALTER TABLE "station" DROP COLUMN "clicktimestamp_iso8601";

CREATE INDEX station_name ON station(name);
CREATE INDEX station_tags ON station(tags);
CREATE INDEX station_countrycode ON station(countrycode);
CREATE INDEX station_languagecodes ON station(languagecodes);
CREATE INDEX station_votes ON station(votes);
CREATE INDEX station_clickcount ON station(clickcount);
CREATE INDEX station_clicktrend ON station(clicktrend);

VACUUM;

select count(*) from station;
EOF

ls -lah "Sources/${PACKAGE}/Resources/${FILE}.db"
shasum -a 256 "Sources/${PACKAGE}/Resources/${FILE}.db"

