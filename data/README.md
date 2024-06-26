# Building the geography CSV files

## Requirements

You’ll need to have a recent PostgreSQL and PostGIS version installed on your computer. It is best to create a new empty database in PostgreSQL to carry out the process of building the tables.

## Data sources

1. [Ordnance Survey Boundary-Line™][1]
2. [ONS Postcode Directory][2]
3. [Welsh Output Area to Constituency to Region Lookup][3]
4. [Constituency Boundaries (Ultra Generalised)][5]
5. [Region Boundaries (Ultra Generalised)][6]
6. [Country Boundaries (Ultra Generalised)][8]
7. [Population statistics for Senedd Cymru constituencies][7]
8. [Population estimates for England, Wales, Scotland and Northern Ireland][9]

The latest version of the ONS Postcode Directory should be used - it is updated every three months.

## Procedure

First, ensure the PostGIS extension is enabled in your database:

``` sql
CREATE EXTENSION postgis;
```

Next, import the constituency boundary line data use the `ogr2ogr` tool.

``` sh
ogr2ogr -nlt PROMOTE_TO_MULTI -f "PostgreSQL" PG:"host=localhost dbname=<your-local-database>" scotland_and_wales_const_region.shp
```

Once this is done you should have the table `scotland_and_wales_const_region` in your database. Since the table contain both Scottish and Welsh boundaries we need to filter out the Welsh data. We can do this by creating a view onto the table and for better performance we can create it as a [materialized view][4].

``` sql
CREATE MATERIALIZED VIEW welsh_constituencies AS
SELECT code, REPLACE(name, ' P Const', '') AS name, wkb_geometry AS boundary
FROM scotland_and_wales_const_region
WHERE area_code = 'WPC'
ORDER BY code;
```

The views also do some housekeeping on the names to remove the unnecessary suffixes for our purposes. For performance reasons later also create the following indexes on the `boundary` column so that the PostGIS `st_within` function can use a simple bounding-box calculation to filter out areas that don't match.

``` sql
CREATE INDEX index_welsh_constituencies_on_boundary ON welsh_constituencies USING GIST (boundary);
```

Whilst the OS data is fine for generating the lookups we need something with less precision for interactive purposes so we’ll use the generalised boundaries from the ONS Open Geography Portal.

First, import the generalised data:

``` sh
ogr2ogr -nlt PROMOTE_TO_MULTI -f "PostgreSQL" PG:"host=localhost dbname=<your-local-database>" -nln welsh_constituency_boundaries -unsetFieldWidth 'SENC_DEC_2022_WA_BUC.shp'
```

Then create an index to optimise performance:

``` sql
CREATE UNIQUE INDEX index_welsh_constituency_boundaries_on_senc22cd ON welsh_constituency_boundaries(senc22cd);
```

That completes the import of constituency data.

Next, import the region boundary line data use the `ogr2ogr` tool.

``` sh
ogr2ogr -nlt PROMOTE_TO_MULTI -f "PostgreSQL" PG:"host=localhost dbname=<your-local-database>" scotland_and_wales_region.shp
```

Once this is done you should have the table `scotland_and_wales_region` in your database. Since the table contain both Scottish and Welsh boundaries we need to filter out the Welsh data. We can do this by creating a materialized view again.

``` sql
CREATE MATERIALIZED VIEW welsh_regions AS
SELECT code, REPLACE(name, ' PER', '') AS name, wkb_geometry AS boundary
FROM scotland_and_wales_region
WHERE area_code = 'WPE'
ORDER BY code;
```

The views also do some housekeeping on the names to remove the unnecessary suffixes for our purposes.

Again, we need to use generalised boundary data for interactive performance so import the ONS data for regions:

``` sh
ogr2ogr -nlt PROMOTE_TO_MULTI -f "PostgreSQL" PG:"host=localhost dbname=<your-local-database>" -nln welsh_region_boundaries -unsetFieldWidth 'SENER_DEC_2022_WA_BUC.shp'
```

Then create an index to optimise performance:

``` sql
CREATE UNIQUE INDEX index_welsh_region_boundaries_on_sener22cd ON welsh_region_boundaries(sener22cd);
```

That completes the import of region data.

Next you’ll need to import the output area to constituency to region lookup. Start off by create a table to hold the import:

``` sql
CREATE TABLE welsh_oa_to_constituency_to_region_lookup (
  OA21CD character(9),
  SENC21CD character(9),
  SENC21NM character varying(100),
  SENER22CD character(9),
  SENER22NM character varying(100),
  ObjectId integer PRIMARY KEY
);
```

Now import the data file using the `COPY` SQL command:

``` sql
COPY welsh_oa_to_constituency_to_region_lookup FROM '/path/to/oa_to_constituency_to_region_lookup.csv' WITH DELIMITER ',' CSV HEADER;
```

If you’re on a Mac you may get a warning about postgres wanting access to the filesystem depending on the path to the CSV file (e.g. if it's on your desktop).

We need to filter this down to just a constituency to region lookup which we’ll do with a materialized view again:

``` sql
CREATE MATERIALIZED VIEW welsh_constituency_to_region_lookup AS
SELECT senc21cd, sener22cd
FROM welsh_oa_to_constituency_to_region_lookup
GROUP BY senc21cd, sener22cd
ORDER BY senc21cd;
```

Also create an index on the constituency code column to make the join more efficient later on:

``` sql
CREATE INDEX index_welsh_constituency_to_region_lookup_on_senc21cd ON welsh_constituency_to_region_lookup(senc21cd);
```

Next you’ll need to import the ONS Postcode Directory. This file is very large (in excess of 1GB) but we only need a subset of the data so create the following table to import into:

``` sql
CREATE TABLE postcodes (
  pcds character varying(8) PRIMARY KEY,
  dointr character(6),
  doterm character(6),
  oseast1m character varying(8),
  osnrth1m character varying(8),
  ctry character(9)
);
```

This is the meaning of each of the columns:

| Column   | Description                             |
|----------|-----------------------------------------|
| pcds     | Unit postcode - variable length version |
| ctry     | Country                                 |
| oseast1m | National grid reference - Easting       |
| osnrth1m | National grid reference - Northing      |
| dointr   | Date of introduction                    |
| doterm   | Date of termination                     |

To do the import you can use the `COPY` SQL command to read the data but you’ll need to process the CSV file through `cut` first:

``` sh
cut -d, -f3,4,5,12,13,17 ONSPD_AUG_2023_UK.csv > ONSPD_REDUCED.csv
```

This reduces the data down to a more manageable ~150MB.

Now import the CSV into the postcodes table:

``` sql
COPY postcodes FROM '/path/to/ONSPD_REDUCED.csv' WITH DELIMITER ',' CSV HEADER;
```

We now need to created materialized views for just the Welsh postcodes:

``` sql
CREATE MATERIALIZED VIEW welsh_postcodes AS
SELECT REPLACE(pcds, ' ', '') AS postcode,
ST_SetSRID(ST_MakePoint(oseast1m::integer, osnrth1m::integer), 27700) AS location
FROM postcodes WHERE ctry = 'W92000004' AND oseast1m != '' AND osnrth1m != '';
```

This view removes the space from the postcode and filters out any postcodes that don't have a corresponding location - the latter are typically PO boxes. We also set the coordinate system of the location to the OS National Grid.

For performance reasons we again create an index on the location column:

``` sql
CREATE INDEX index_welsh_postcodes_on_location ON welsh_postcodes USING GIST (location);
```

Next we need to create the population figures for the constituencies and regions. To do this we use the MS Excel spreadsheet from GOV.WALES from the list at the start - the figures are in column C of the 'Pop1' sheet. Create two CSVs - one for constituencies and one for regions with the ONS code as the first column and the population figure as the second. Now create tables to hold the data like this:

``` sql
CREATE TABLE welsh_population_by_constituency (
  code character(9) PRIMARY KEY,
  population integer
);

CREATE TABLE welsh_population_by_region (
  code character(9) PRIMARY KEY,
  population integer
);
```

Import the CSVs into the tables using the `COPY` command:

``` sql
COPY welsh_population_by_constituency FROM '/path/to/population_by_constituency.csv' WITH DELIMITER ',' CSV HEADER;
COPY welsh_population_by_region FROM '/path/to/population_by_region.csv' WITH DELIMITER ',' CSV HEADER;
```

You should now have all the data you need to create the lookup tables.

## Creating the lookups

This stage is the core of the processing - for each postcode we need to run a `st_within` function against each constituency/region boundary to check which one it is in. Again for performance reasons we’ll use materialized views:

``` sql
CREATE MATERIALIZED VIEW welsh_postcode_lookup AS
SELECT p.postcode, r.sener22cd AS region_id, c.code AS constituency_id
FROM welsh_postcodes p
JOIN welsh_constituencies c ON st_within(p.location, c.boundary)
JOIN welsh_constituency_to_region_lookup AS r ON c.code = r.senc21cd;
```

This is the final table we need to generate our constituency and region geography CSV files - export using the following `COPY` commands:

``` sql
# regions.csv
COPY (
  SELECT r.code AS id, b.sener22nm AS name_en, b.sener22nmw AS name_cy, u.population,
  ST_AsEWKT(ST_ReducePrecision(ST_Transform(b.wkb_geometry, 4326), 0.0001)) AS boundary
  FROM welsh_regions AS r
  INNER JOIN welsh_region_boundaries AS b ON r.code = b.sener22cd
  INNER JOIN welsh_population_by_region AS u ON r.code = u.code
  ORDER BY r.code
) TO '/path/to/regions.csv' WITH CSV HEADER FORCE QUOTE *;
```

``` sql
# constituencies.csv
COPY (
  SELECT c.code AS id, (
    SELECT r.region_id
    FROM welsh_postcode_lookup AS r
    WHERE r.constituency_id = c.code LIMIT 1
  ) AS region_id,
  b.senc22nm AS name_en, b.senc22nmw AS name_cy, (
    SELECT p.postcode
    FROM welsh_postcode_lookup AS p
    WHERE p.constituency_id = c.code
    ORDER BY random() LIMIT 1
  ) AS example_postcode,
  u.population,
  ST_AsEWKT(ST_ReducePrecision(ST_Transform(b.wkb_geometry, 4326), 0.0001)) AS boundary
  FROM welsh_constituencies AS c
  INNER JOIN welsh_constituency_boundaries AS b ON c.code = b.senc22cd
  INNER JOIN welsh_population_by_constituency AS u ON c.code = u.code
  ORDER BY c.code
) TO '/path/to/constituencies.csv' WITH CSV HEADER FORCE QUOTE *;
```

``` sql
# postcodes.csv
COPY (
  SELECT postcode AS id, constituency_id
  FROM welsh_postcode_lookup ORDER BY postcode
) TO '/path/to/postcodes.csv' WITH CSV HEADER FORCE QUOTE *;
```

The `ST_Transform` method transforms the co-ordinates from OSGB National Grid to WGS84 and the `ST_ReducePrecision` removes the excess precision in the ONS boundaries.

Send the `regions.csv` and `constituencies.csv` to the translations team to fill out the `name_gd` column. Once received replace the existing files and commit to the repo.

## Countries

The country data is much simpler to generate, first import the generalised boundary data:

``` sh
ogr2ogr -nlt PROMOTE_TO_MULTI -f "PostgreSQL" PG:"host=localhost dbname=<your-local-database>" -nln countries -unsetFieldWidth CTRY_DEC_2021_UK_BUC.shp
```

Next create a table for the population figures obtained from the ONS mid-year estimates - the columns E-H and rows 8-9 are the figures you need:

```
CREATE TABLE population_by_country (
  code character varying(9) PRIMARY KEY,
  population integer NOT NULL
);

COPY population_by_country FROM '/path/to/population_by_country.csv' WITH DELIMITER ',' CSV HEADER;
```

Finally, create the countries.csv file in a similar manner to the constituency and region CSV files:

``` sql
#countries.csv
COPY (
  SELECT
    c.ctry21cd AS id,
    c.ctry21nm AS name_en,
    c.ctry21nmw AS name_cy,
    p.population,
    ST_AsEWKT(ST_ReducePrecision(ST_Transform(c.wkb_geometry, 4326), 0.0001)) AS boundary
  FROM countries AS c
  INNER JOIN population_by_country AS p ON c.ctry21cd = p.code
  ORDER BY c.ctry21cd
) TO '/path/to/countries.csv' WITH CSV HEADER FORCE QUOTE *;
```

[1]: https://osdatahub.os.uk/downloads/open/BoundaryLine
[2]: https://geoportal.statistics.gov.uk/datasets/ons-postcode-directory-august-2023/about
[3]: https://geoportal.statistics.gov.uk/datasets/ons::output-area-2021-to-senedd-cymru-constituency-to-senedd-cymru-electoral-region-december-2022-lookup-in-wales/explore
[4]: https://www.postgresql.org/docs/11/sql-creatematerializedview.html
[5]: https://geoportal.statistics.gov.uk/datasets/ons::senedd-cymru-constituencies-december-2022-boundaries-wa-buc-2/explore
[6]: https://geoportal.statistics.gov.uk/datasets/ons::senedd-cymru-electoral-regions-december-2022-wa-buc-2/explore
[7]: https://gov.wales/data-senedd-cymru-constituency-areas-2021
[8]: https://geoportal.statistics.gov.uk/datasets/ons::countries-december-2021-uk-buc/about
[9]: https://www.ons.gov.uk/peoplepopulationandcommunity/populationandmigration/populationestimates/datasets/populationestimatesforukenglandandwalesscotlandandnorthernireland
