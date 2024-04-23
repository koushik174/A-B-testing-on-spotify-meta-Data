create database spotify_db;

create or replace storage integration s3_init
  type = EXTERNAL_STAGE
  storage_provider = S3
  enabled = true
  storage_aws_role_arn = 'arn:aws:iam::471112522758:role/spotify-snowflake-role'
  storage_allowed_locations = ('s3://spotify-etl-koushik')
  comment = 'Creating connection to S3';

DESC integration s3_init;

CREATE OR REPLACE file format csv_fileformat
    type = csv
    field_delimiter = ','
    skip_header = 1
    null_if = ('NULL','null')
    empty_field_as_null = True;

CREATE OR REPLACE STAGE spotify_stage
      URL = 's3://spotify-etl-koushik/transformed_data/'
      STORAGE_INTEGRATION = s3_init
      FILE_FORMAT = csv_fileformat;
LIST @spotify_stage/songs

CREATE OR REPLACE TABLE tbl_album(
   album_id STRING,
   name STRING,
   release_date DATE,
   total_tracks INT,
   url STRING
);
CREATE OR REPLACE TABLE tbl_artists(
   artist_id STRING,
   name STRING,
   url STRING
);
CREATE OR REPLACE TABLE tbl_songs(
   song_id STRING,
   song_name STRING,
   duration_ms INT,
   url STRING,
   popularity INT,
   song_added DATE,
   album_id STRING,
   artist_id STRING
);

COPY INTO tbl_album
FROM @spotify_stage/album/album_transformed_2024-04-21/run-1713715470484-part-r-00000

COPY INTO tbl_artists
FROM @spotify_stage/artist/artist_transformed_2024-04-21/run-1713715481920-part-r-00000

COPY INTO tbl_songs
FROM @spotify_stage/songs/songs_transformed_2024-04-21/run-1713715483988-part-r-00006

CREATE OR REPLACE SCHEMA pipe;

CREATE OR REPLACE pipe pipe.tbl_album_pipe
auto_ingest = True
AS
COPY INTO tbl_album
FROM @spotify_stage/songs/;

CREATE OR REPLACE pipe pipe.tbl_artists_pipe
auto_ingest = True
AS
COPY INTO tbl_artists
FROM @spotify_stage/artists/;

CREATE OR REPLACE pipe pipe.tbl_songs_pipe
auto_ingest = True
AS
COPY INTO tbl_songs
FROM @spotify_stage/songs/;

DESC pipe pipe.tbl_songs_pipe;

SELECT COUNT(*) FROM tbl_songs;