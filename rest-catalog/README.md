# rest-catalog
NOT YET FULLY IMPLEMENTED (AI sloppy)

Use the Iceberg REST catalog as an authoritative source for tracking a collection of tables and their current metadata.


## Overview

This project demonstrates using Spark with the Iceberg REST catalog backed by S3-compatible object storage.

The [Iceberg REST catalog is described by an official OpenAPI specification](rest-spec). In this example, we'll use Spark
shell running on the host machine to connect to Docker containers running an Iceberg REST catalog and a Minio server.

---

**WARNING:** **Split-Context Hostname Problem**

The system setup described by this project has an unfortunate problem related to hostnames and which arises because we
are running processes inside Docker and processes on the host.

In this system, Iceberg tables are stored in object storage served by a Minio server running in Docker. Other Docker
containers in the system can reach the Minio server at the hostname `minio` thanks to the convenient networking Docker
provides among containers running in the same Docker network.

By contrast, processes running on the host machine (like the Spark shell we're using in this project) are operating
outside this Docker networking context, and can normally only reach the Minio server at `localhost` and using the ports
exposed by the Minio server and Docker.

The Iceberg REST catalog wants to address Iceberg tables using `minio` URLs (but does it need to actually write or
read anything from it??? The version hint?) but the Spark shell running on the host machine wants to address the tables
using `localhost` URLs. And... now I'm a little confused why this isn't possible but I get errors because I think that
the catalog was actually writing the metadata files??? I had data files on my host at `/tmp/warehouse` but missing the
metadata files.

---


## Instructions

Follow these instructions to create and interact with Iceberg tables using the REST catalog with S3 storage.

1. Pre-requisite: Java
    * I'm using Java 21
2. Pre-requisite: Spark
    * I'm using Spark 3.5.x installed with Homebrew
3. Pre-requisite: Docker and Docker Compose
    * For running the Iceberg REST catalog service and Minio
4. Pre-requisite: MinIO Client (`mc`)
    * I'm using `mc` RELEASE.2025-03-12T17-29-24Z installed with Homebrew
5. Edit the `/etc/hosts/` file to add the `minio` entry
    * ```text
      127.0.0.1       minio
      ```
6. Start the Iceberg REST catalog and Minio servers:
    * ```shell
      docker compose up -d
      ```
7. Configure a MinIO client alias to the local server with the following command:
    * ```shell
      mc alias set local http://localhost:9000 minioadmin minioadmin
      ```
8. (NOT NEEDED because all actors are using the minio admin creds?) Create a bucket to use for the warehouse and make it publicly accessible:
    * ```shell
      mc mb local/warehouse
      mc anonymous set public local/warehouse
      ```
9. Start a Spark shell session configured to use the REST catalog:
    * ```shell
      SPARK_CONF_DIR=. SPARK_LOCAL_IP=127.0.0.1 spark-shell --packages org.apache.iceberg:iceberg-spark-runtime-3.5_2.12:1.8.1,org.apache.hadoop:hadoop-aws:3.3.4
      ```
10. Define a table using the REST catalog:
     * ```scala
       spark.sql("""
           create table rest.db.messages (
               id int,
               message string
           )
           using iceberg
       """)
       ```
Unfortunately the above command fails with the following error:
```text
scala> spark.sql("""
     |     create table rest.db.messages (
     |         id int,
     |         message string
     |     )
     |     using iceberg
     | """)
Loading custom FileIO implementation: org.apache.iceberg.io.ResolvingFileIO
org.apache.iceberg.exceptions.ServiceFailureException: Server error: SdkClientException: Received an UnknownHostException when attempting to interact with a service. See cause for the exact endpoint that is failing to resolve. If this is happening on an endpoint that previously worked, there may be a network connectivity issue or your DNS cache could be storing endpoints for too long.
```

This is really annoying. This is the same type of problem we run into when using Kafka with Docker. The Kafka broker advertises
a Docker hostname (like `my-kafka-broker`) but of course on the host computer is not inside the Docker network so none
of thost hosts it can resolve.... But with Docker we fix this with `KAFKA_ADVERTISED_LISTENERS` settings. What am I
supposed to with this Minio Docker crap?


10. Write some sample data:
     * ```scala
       spark.sql("""
           insert into rest.db.messages values
               (1, 'Hello REST catalog!'),
               (2, 'Iceberg + REST API is powerful!')
       """)
       ```
11. Read the data:
     * ```scala
       spark.sql("select * from rest.db.messages order by id").show()
       ```
12. Check the table metadata:
     * ```scala
       spark.sql("select * from rest.db.messages.snapshots").show(truncate=false)
       ```
     * ```scala
       spark.sql("select * from rest.db.messages.history").show(truncate=false)
       ```
     * ```scala
       spark.sql("select * from rest.db.messages.files").show(truncate=false)
       ```
13. Explore data in Minio:
    * Open the Minio console at [http://localhost:9001](http://localhost:9001)
    * Login with username `minioadmin` and password `minioadmin`
    * Navigate to the `warehouse` bucket to see the data and metadata files
    * You should see a directory structure that contains your table data and metadata
14. When you're done, quit the Spark shell:
    * ```scala
      :quit
      ```
15. Stop the Docker containers:
    * ```shell
      docker compose down
      ```

## How Data is Stored and Accessed

(This section is AI sloppy)

When using Iceberg with S3 (via Minio in our case), the data is organized as follows:

1. **Table Data**: The actual table data is stored as Parquet files in the S3 bucket.

2. **Table Metadata**: Iceberg maintains metadata files that track the state of the table, including:
    - Metadata JSON files: Contains the overall table metadata
    - Manifest lists (avro files): Lists of manifest files for each snapshot
    - Manifest files (avro files): Lists of data files for each snapshot

3. **Catalog Metadata**: The REST catalog service maintains a mapping between table names and metadata file locations.

In our setup:
- The REST catalog service stores the mapping between `rest.db.messages` and its metadata file location
- Minio stores both the table data files and the Iceberg metadata files in the warehouse bucket
- When Spark executes a query, it:
    1. Asks the REST catalog for the table's metadata location
    2. Fetches the metadata from Minio
    3. Uses the metadata to locate the relevant data files in Minio
    4. Reads the data files directly from Minio

This separation of concerns allows for efficient and scalable data processing.

## Accessing the REST Catalog with curl

One of the key benefits of the REST Catalog is the ability to interact with tables using HTTP requests. Here are some example curl commands:


### Get catalog configuration
```bash
curl -s http://localhost:8181/v1/config | jq
```


### List all namespaces
```bash
curl -s http://localhost:8181/v1/namespaces | jq
```


### List all tables in a namespace
```bash
curl -s http://localhost:8181/v1/namespaces/db/tables | jq
```


### Get table metadata
```bash
curl -s http://localhost:8181/v1/namespaces/db/tables/messages | jq
```

For a complete list of REST API endpoints, see the [Iceberg REST catalog API Specification][rest-spec].


## Wish List

General clean-ups, TODOs and things I wish to implement for this subproject:

* [x] Showcase using the REST API to show the table metadata (added curl examples)
* [ ] Clean up "where does the data go?" Figure out `CATALOG_WAREHOUSE`
* [ ] IN PROGRESS (This should resolve the problem around locating 'where does the data go' ...) S3 with Minio
   * This is hard. Split-brain problem. And I need debugging so I'm going to run the catalog on my host for the short
     term. This should be easy enough because there is a [`public static void main` method to do this in the Iceberg
     codebase](https://github.com/apache/iceberg/blob/fcea78fc3571063fa172edd96be00b1fab0ba68e/open-api/src/testFixtures/java/org/apache/iceberg/rest/RESTCatalogServer.java#L129).
* [ ] Really differentiate "metadata" that's stored by the catalog vs. "metadata" in the table's `metadata` directory.
  I'm really confused by that.
* [ ] I really don't get the concurrency story when it comes to writing data. 
* [ ] Consider broadening this subproject to just `catalog` and maybe use it as a vehicle for showing the concurrency
  story? (at least for writers; concurrency for readers I think is pretty straightforward but not sure)


## Reference

* [Iceberg REST catalog API Specification][rest-spec]


[rest-spec]: https://github.com/apache/iceberg/blob/master/open-api/rest-catalog-open-api.yaml
