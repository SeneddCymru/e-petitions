# Building the geography CSV files

## Requirements

You’ll need to have a recent PostgreSQL and PostGIS version installed on your computer. It is best to create a new empty database in PostgreSQL to carry out the process of building the tables.

## Data sources

1. [Ordnance Survey Boundary-Line™][1]
2. [ONS Postcode Directory][2]
3. [Scottish Parliamentary Constituency to Region Lookup][3]

The latest version of the ONS Postcode Directory should be used - it is updated every three months.

Import the constituency boundary line data use the `ogr2ogr` tool. 

``` sh
ogr2ogr -nlt PROMOTE_TO_MULTI -f "PostgreSQL" PG:"host=localhost dbname=<your-local-database>" scotland_and_wales_const_region.shp
```

Once this is done you should have the table `scotland_and_wales_const_region` in your database. Since the table contain both Scottish and Welsh boundaries we need to filter out the Welsh data. We can do this by creating a view onto the table and for better performance we can create it as a [materialized view][4].

``` sql
CREATE MATERIALIZED VIEW scottish_constituencies AS
SELECT code, REPLACE(name, ' P Const', '') AS name, wkb_geometry AS boundary
FROM scotland_and_wales_const_region
WHERE area_code = 'SPC'
ORDER BY code;
```

The views also do some housekeeping on the names to remove the unnecessary suffixes for our purposes. For performance reasons later also create the following indexes on the `boundary` column so that the PostGIS `st_within` function can use a simple bounding-box calculation to filter out areas that don't match.

``` sql
CREATE INDEX index_scottish_constituencies_on_boundary ON scottish_constituencies USING GIST (boundary);
```

Next you’ll need to import the constituency to region lookup. Start off by create a table to hold the import:

``` sql
CREATE TABLE scottish_constituency_to_region_lookup (
  FID integer PRIMARY KEY,
  SPC20CD character(9),
  SPC20NM character varying(100),
  SPR20CD character(9),
  SPR20NM character varying(100)
);
```

Also create an index on the constituency code column to make the join more efficient later on:

``` sql
CREATE INDEX index_scottish_constituency_to_region_lookup_on_SPC20CD ON scottish_constituency_to_region_lookup(SPC20CD);
```

Now import the data file using the `COPY` SQL command:

``` sql
COPY scottish_constituency_to_region_lookup FROM '/path/to/constituency_to_region_lookup.csv' WITH DELIMITER ',' CSV HEADER;
```

If you’re on a Mac you may get a warning about postgres wanting access to the filesystem depending on the path to the CSV file (e.g. if it's on your desktop).

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
cut -d, -f3,4,5,12,13,17 ONSPD_NOV_2020_UK.csv > ONSPD_REDUCED.csv
```

This reduces the data down to a more manageable 200MB.

Now import the CSV into the postcodes table:

``` sql
COPY postcodes FROM '/path/to/ONSPD_REDUCED.csv' WITH DELIMITER ',' CSV HEADER;
```

We now need to created materialized views for just the Scottish postcodes:

``` sql
CREATE MATERIALIZED VIEW scottish_postcodes AS
SELECT REPLACE(pcds, ' ', '') AS postcode, 
ST_SetSRID(ST_MakePoint(oseast1m::integer, osnrth1m::integer), 27700) AS location 
FROM postcodes WHERE ctry = 'S92000003' AND oseast1m != '' AND osnrth1m != '';
```

This view removes the space from the postcode and filters out any postcodes that don't have a corresponding location - the latter are typically PO boxes. We also set the coordinate system of the location to the OS National Grid.

For performance reasons we again create an index on the location column:

``` sql
CREATE INDEX index_scottish_postcodes_on_location ON scottish_postcodes USING GIST (location);
```

You should now have all the data you need to create the lookup tables.

## Creating the lookups

This stage is the core of the processing - for each postcode we need to run a `st_within` function against each constituency/region boundary to check which one it is in. Again for performance reasons we’ll use materialized views:

``` sql
CREATE MATERIALIZED VIEW scottish_postcode_lookup AS
SELECT p.postcode, r.spr20cd AS region_id, c.code AS constituency_id
FROM scottish_postcodes p
JOIN scottish_constituencies c ON st_within(p.location, c.boundary)
JOIN scottish_constituency_to_region_lookup AS r ON c.code = r.spc20cd;
```

This is the final table we need to generate our final geography CSV files - export using the following `COPY` commands:

``` sql
# regions.csv
COPY (
  SELECT r.code AS id, r.name AS name_en, '' AS name_gd
  FROM scottish_regions AS r ORDER BY r.name_en
) TO '/path/to/regions.csv' WITH CSV HEADER FORCE QUOTE *;
```

``` sql
# constituencies.csv
COPY (
  SELECT c.code AS id, (
    SELECT r.region_id
    FROM scottish_postcode_lookup AS r
    WHERE r.constituency_id = c.code LIMIT 1
  ) AS region_id,
  c.name AS name_en, '' AS name_gd, (
    SELECT p.postcode 
    FROM scottish_postcode_lookup AS p 
    WHERE p.constituency_id = c.code
    ORDER BY random() LIMIT 1
  ) AS example_postcode
  FROM scottish_constituencies AS c
  ORDER BY name_en
) TO '/path/to/constituencies.csv' WITH CSV HEADER FORCE QUOTE *;
```

``` sql
# postcodes.csv
COPY (
  SELECT postcode AS id, constituency_id
  FROM scottish_postcode_lookup ORDER BY postcode
) TO '/path/to/postcodes.csv' WITH CSV HEADER FORCE QUOTE *;
```

Send the `regions.csv` and `constituencies.csv` to the translations team to fill out the `name_gd` column. Once received replace the existing files and commit to the repo.

[1]: https://osdatahub.os.uk/downloads/open/BoundaryLine
[2]: https://geoportal.statistics.gov.uk/datasets/ons-postcode-directory-november-2020
[3]: https://geoportal.statistics.gov.uk/datasets/9b4294d9354e41789ae20686babcc19a_0
[4]: https://www.postgresql.org/docs/12/sql-creatematerializedview.html
