#!/bin/bash -e

# always delete, since modifying w/ drop & re-all will change file checksum
touch Sources/App/Resources/places.db
rmbk Sources/App/Resources/places.db

EXPORT="cities500"
#EXPORT="cities1000"
#EXPORT="cities5000"
#EXPORT="cities15000"

# see: http://download.geonames.org/export/dump/readme.txt
curl -fL "https://download.geonames.org/export/dump/${EXPORT}.zip" | bsdtar -xOf - > /tmp/places.tsv

sqlite3 Sources/App/Resources/places.db << EOF
DROP TABLE IF EXISTS place;

CREATE TABLE place (
    "id" INTEGER PRIMARY KEY, -- integer id of record in geonames database
    "name" TEXT,         -- name: name of geographical point (utf8) varchar(200)
    "asciiname" TEXT,    -- asciiname: name of geographical point in plain ascii characters, varchar(200)
    "alternatenames" TEXT, -- alternatenames: alternatenames, comma separated, ascii names automatically transliterated, convenience attribute from alternatename table, varchar(10000)
    "latitude" REAL,     -- latitude: latitude in decimal degrees (wgs84)
    "longitude" REAL,    -- longitude: longitude in decimal degrees (wgs84)
    "featureclass" TEXT, -- feature class: see http://www.geonames.org/export/codes.html, char(1)
    "featurecode" TEXT,  -- feature code: see http://www.geonames.org/export/codes.html, varchar(10)
    "countrycode" TEXT,  -- country code: ISO-3166 2-letter country code, 2 characters
    "cc2" TEXT,          -- cc2: alternate country codes, comma separated, ISO-3166 2-letter country code, 200 characters
    "admincode1" TEXT,   -- admin1 code: fipscode (subject to change to iso code), see exceptions below, see file admin1Codes.txt for display names of this code; varchar(20)
    "admincode2" TEXT,   -- admin2 code: code for the second administrative division, a county in the US, see file admin2Codes.txt; varchar(80) 
    "admincode3" TEXT,   -- admin3 code: code for third level administrative division, varchar(20)
    "admincode4" TEXT,   -- admin4 code: code for fourth level administrative division, varchar(20)
    "population" INTEGER,-- population: bigint (8 byte int) 
    "elevation" INTEGER, -- elevation: in meters, integer
    "dem" INTEGER,       -- dem: digital elevation model
    "timezone" TEXT,     -- timezone: the iana timezone id varchar(40)
    "modified" TEXT       -- date of last modification in yyyy-MM-dd format
);

.mode tabs
.import /tmp/places.tsv place

DELETE FROM "place" WHERE "population" < 10000; 

ALTER TABLE "place" DROP COLUMN "alternatenames"; -- 11M -> 6.4M (sqlite v3.37.2+)

CREATE INDEX place_name ON place(name);
-- CREATE INDEX place_asciiname ON place(asciiname);
CREATE INDEX place_latitude ON place(latitude);
CREATE INDEX place_longitude ON place(longitude);
-- CREATE INDEX place_population ON place(population);
CREATE INDEX place_countrycode ON place(countrycode);
CREATE INDEX place_timezone ON place(timezone);

VACUUM;

select count(*) from place;
select count(distinct countrycode) from place;
EOF

ls -lah Sources/App/Resources/places.db
shasum -a 256 Sources/App/Resources/places.db

