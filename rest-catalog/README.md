# rest-catalog
NOT YET FULLY IMPLEMENTED (AI sloppy)

Use the Iceberg REST catalog as an authoritative source for tracking a collection of tables and their current metadata.


## Overview

This project demonstrates using Spark with the Iceberg REST catalog backed by S3-compatible object storage.

The [Iceberg REST catalog is described by an official OpenAPI specification](rest-spec). In this example, we'll use Spark
shell running on the host machine to connect to Docker containers running an Iceberg REST catalog and a Minio server.


## Instructions

Follow these instructions to create and interact with Iceberg tables using the REST catalog with S3 storage.

1. Pre-requisite: Java
    * I'm using Java 21
2. Pre-requisite: Spark
    * I'm using Spark 3.5.x installed with Homebrew
3. Pre-requisite: Docker
4. Pre-requisite: MinIO Client (`mc`)
    * I'm using `mc` RELEASE.2025-03-12T17-29-24Z installed with Homebrew
5. Run the Iceberg REST catalog server from its project dir with the following env vars:
    * ```shell
      export AWS_ACCESS_KEY_ID=minioadmin
      export AWS_SECRET_ACCESS_KEY=minioadmin
      export AWS_REGION=us-east-1
      export CATALOG_WAREHOUSE=s3://warehouse
      export CATALOG_IO__IMPL=org.apache.iceberg.aws.s3.S3FileIO
      export CATALOG_S3_ENDPOINT=http://localhost:9000
      export CATALOG_S3_PATH__STYLE__ACCESS=true
      ```
    * Unfortunately the Iceberg REST server "fixture" distributed by the Iceberg project is not exactly documented. This
      is somewhat understandable because it's designed to be a test fixture, and not a production server. But still, it's
      been hard to get it to work because there is a decent amount of configuration that you need to get right and the
      amount of indirection in the Iceberg AWS/S3 implementation plus the AWS S3 client library itself is a bit high.
    * See <https://github.com/apache/iceberg/blob/c7f3919f847ae8c4f661299fd0a64db4dde1a583/aws/src/main/java/org/apache/iceberg/aws/s3/S3FileIOProperties.java#L232>
    * See <https://github.com/apache/iceberg/blob/c7f3919f847ae8c4f661299fd0a64db4dde1a583/open-api/src/testFixtures/java/org/apache/iceberg/rest/RCKUtils.java#L45>
    * ```shell
      <path-to-catalog-server>/build/install/catalog-server/bin/catalog-server
      ```
6. Start the Minio server:
    * ```shell
      docker compose up -d
      ```
7. Configure a MinIO client alias to the local server with the following command:
    * ```shell
      mc alias set local http://localhost:9000 minioadmin minioadmin
      ```
8. Create a bucket to use for the warehouse:
    * ```shell
      mc mb local/warehouse
      ```
9. Start a Spark shell session configured to use the REST catalog:
    * ```shell
      AWS_ACCESS_KEY_ID=minioadmin AWS_SECRET_ACCESS_KEY=minioadmin AWS_REGION=us-east-1 SPARK_CONF_DIR=. SPARK_LOCAL_IP=127.0.0.1 spark-shell --packages org.apache.iceberg:iceberg-spark-runtime-3.5_2.12:1.8.1,org.apache.iceberg:iceberg-aws-bundle:1.8.1
      ```
    * TODO Can we set the keys in `spark-defaults.conf`? This command is too noisy.
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
11. Write some sample data:
     * ```scala
       spark.sql("""
           insert into rest.db.messages values
               (1, 'The Spark shell says hello'),
               (2, 'The Iceberg REST catalog API is neat')
       """)
       ```
12. Read the data:
     * ```scala
       spark.sql("select * from rest.db.messages order by id").show()
       ```
13. Explore data in Minio:
    * Open the Minio console at [http://localhost:9001](http://localhost:9001)
    * Login with username `minioadmin` and password `minioadmin`
    * Navigate to the `warehouse` bucket to see the data and metadata files
    * You should see a directory structure that contains your table data and metadata
14. View the table metadata via the REST API:
    * TODO Move the later curl commands into this part.
15. When you're done, quit the Spark shell:
    * ```scala
      :quit
      ```
16. Stop the Docker containers:
    * ```shell
      docker compose down
      ```


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
   * Try the REST catalog Docker container again
   * Add "overview" description and describe that S3 is in the picture as a way to store the data. A common storage
     point for both the catalog and tenant applications to access the data. Remember, the catalog does ACID stuff and
     writes the `metata...json` files (90% sure). I think the tenant apps actually write the manifest files (80% sure)
     which confusingly write into the `metadata/` directory. The tenant apps of course read and write the `data/`
     directory.
* [ ] Really differentiate "metadata" that's stored by the catalog vs. "metadata" in the table's `metadata` directory.
  I'm really confused by that.
* [ ] I really don't get the concurrency story when it comes to writing data. 
* [ ] Consider broadening this subproject to just `catalog` and maybe use it as a vehicle for showing the concurrency
  story? (at least for writers; concurrency for readers I think is pretty straightforward but not sure)
* [ ] Try to scale down the config to the bare minimum. This will be in part trial and error. I think there is more
  credential stuff I don't need, for example.


## Reference

* [Iceberg REST catalog API Specification][rest-spec]


[rest-spec]: https://github.com/apache/iceberg/blob/master/open-api/rest-catalog-open-api.yaml
