# rest-catalog

Use the Iceberg REST catalog as an authoritative source for tracking a collection of tables and their current metadata.


## Overview

This project showcases an Apache Iceberg data system featuring the Iceberg REST catalog, object storage, and the Spark
shell. Spark runs on the host machine and connects to the Iceberg REST catalog server and Minio servers running in
Docker containers. The catalog server also interacts with the Minio server to query and update table metadata.

An Iceberg catalog will typically be involved in a production Iceberg data system. In some systems, the catalog might
be implemented in HDFS. In other systems, it might be in an RDBMS. The Iceberg REST catalog is an abstraction over the
underlying catalog implementation and [it is described by an official OpenAPI specification](rest-spec). This
specification and the ubiquity of HTTP/JSON makes it easier for other software to implement an integration with the
Icerberg REST catalog. For example, [DuckDB integrates with the Iceberg REST catalog](https://github.com/duckdb/duckdb-iceberg/pull/98)
and not the other catalog forms.

This project also features S3-compatible object storage as the storage layer for Iceberg table metadata and table
data. This is the typical choice for Iceberg data systems.

This project is designed to make clear the essential components and configuration in a system using this
technology stack.


## Instructions

Follow these instructions to execute the demo.

1. Pre-requisite: Java
    * I'm using Java 21
2. Pre-requisite: Spark
    * I'm using Spark 3.5.x installed with Homebrew
3. Pre-requisite: Docker
4. Pre-requisite: MinIO Client (`mc`)
    * I'm using `mc` RELEASE.2025-03-12T17-29-24Z installed with Homebrew
5. Start the Minio and REST catalog servers:
    * ```shell
      docker compose up --detach
      ```
6. Configure a MinIO client alias for the local server:
    * ```shell
      mc alias set local http://localhost:9000 minioadmin minioadmin
      ```
7. Create a bucket to use for the warehouse:
    * ```shell
      mc mb local/warehouse
      mc anonymous set public local/warehouse
      ```
8. Start a Spark shell session configured to use the REST catalog:
    * ```shell
      SPARK_CONF_DIR=. SPARK_LOCAL_IP=127.0.0.1 AWS_REGION=us-east-1 spark-shell
      ```
    * Pay attention to the configurations expressed in environment variables and config files. This is important trivia
      to be familiar with.
9. Define a table using the REST catalog:
    * ```scala
      spark.sql("""
          create table rest.db.messages (
              id int,
              message string
          )
          using iceberg
      """)
      ```
10. Write some sample data:
     * ```scala
       spark.sql("""
           insert into rest.db.messages values
               (1, 'The Spark shell says hello'),
               (2, 'The Iceberg REST catalog API is neat')
       """)
       ```
11. Read the data:
     * ```scala
       spark.sql("select * from rest.db.messages order by id").show()
       ```
12. Explore data in Minio:
    * Open the Minio console at [http://localhost:9001](http://localhost:9001)
    * Login with username `minioadmin` and password `minioadmin`
    * Navigate to the `warehouse` bucket to see the data and metadata files
    * You should see a directory structure that contains your table data and metadata
13. View the catalog and table metadata via the REST API:
    * List all namespaces:
    * ```shell
      curl -s http://localhost:8181/v1/namespaces | jq
      ```
    * List all tables in a namespace:
    * ```shell
      curl -s http://localhost:8181/v1/namespaces/db/tables | jq
      ```
    * Get table metadata:
    * ```shell
      curl -s http://localhost:8181/v1/namespaces/db/tables/messages | jq
      ```
14. When you're done, quit the Spark shell:
    * ```scala
      :quit
      ```
15. Stop the Docker containers:
    * ```shell
      docker compose down
      ```

      
## BONUS: Use DuckDB to read data from the Iceberg table

The advantage of a data system that "codes to common interfaces" like Apache Iceberg and S3 is that we can use a variety
of different tools on the data. In this project, we've been using Spark (JVM) but now let's use DuckDB (C++). We can
read the Iceberg table data in two styles: directly vs. catalog.

With the following command, read directly from the Iceberg table without consulting the catalog. This is fine, but
notice how we have to know the incidental 'warehouse/db' knowledge and also use the `unsafe_enable_version_guessing` setting.

```shell
duckdb -c "
CREATE SECRET minio (
    TYPE s3,
    URL_STYLE 'path',
    USE_SSL false,
    ENDPOINT 'localhost:9000'
);

SET unsafe_enable_version_guessing = true;

select * from iceberg_scan('s3://warehouse/db/messages')
"
```


Now, let's try consulting the REST catalog:

```shell
duckdb -c "
CREATE SECRET minio (
    TYPE s3,
    URL_STYLE 'path',
    USE_SSL false,
    ENDPOINT 'localhost:9000'
);

ATTACH '' as my_catalog (TYPE ICEBERG, ENDPOINT 'http://localhost:8181');

select * from my_catalog.db.messages;
"
```

A major advantage of using the catalog is that we can *discover* the tables and their metadata using a command like `show all tables;`
This is an important everyday operation for an analyst or operator of the data system.


## Wish List

General clean-ups, TODOs and things I wish to implement for this subproject:

* [x] Showcase using the REST API to show the table metadata (added curl examples)
* [x] DONE (This should resolve the problem around locating 'where does the data go' ...) S3 with Minio
   * (UPDATE: This was NOT the problem) This is hard. Split-brain problem. And I need debugging so I'm going to run the catalog on my host for the short
     term. This should be easy enough because there is a [`public static void main` method to do this in the Iceberg
     codebase](https://github.com/apache/iceberg/blob/fcea78fc3571063fa172edd96be00b1fab0ba68e/open-api/src/testFixtures/java/org/apache/iceberg/rest/RESTCatalogServer.java#L129).
   * DONE Try the REST catalog Docker container again
* [x] DONE (ok enough) Add "overview" description and describe that S3 is in the picture as a way to store the data. A common storage
  point for both the catalog and tenant applications to access the data. Remember, the catalog does ACID stuff and
  writes the `metadata...json` files (90% sure). I think the tenant apps actually write the manifest files (80% sure)
  which confusingly write into the `metadata/` directory. The tenant apps of course read and write the `data/`
  directory.
* [ ] Really differentiate "metadata" that's stored by the catalog vs. "metadata" in the table's `metadata` directory.
  I'm really confused by that.
* [ ] I really don't get the concurrency story when it comes to writing data. 
* [ ] Consider broadening this subproject to just `catalog` and maybe use it as a vehicle for showing the concurrency
  story? (at least for writers; concurrency for readers I think is pretty straightforward but not sure)
* [x] DONE Try to scale down the config to the bare minimum. This will be in part trial and error. I think there is more
  credential stuff I don't need, for example.
* [x] DONE DuckDB. It newly has catalog support (for reads). It makes the story of the REST catalog more catalog: multiple
  tenants (Spark, DuckDB).
* [ ] Wait a minute.... Did I make this much more complicated than it needs to be? I made the Iceberg REST catalog
  backed by S3 storage? That's what it looks like I did. But I didn't think that was possible. I thought you needed a
  transactional system like HDFS or an RDBMS. Does the S3 integration of the catalog meet the ACID requirements? Or is
  it as a unsound as a local filesystem based catalog? I'm confused, but I'm very glad I have a working system.


## Reference

* [Iceberg REST catalog API Specification][rest-spec]
* [Iceberg Quickstart for Spark][quickstart]
  * The `iceberg-playground/rest-catalog` is modeled similarly to the Spark quickstart example but without using Spark
    in a Docker container and instead using Spark shell from the host. This is a closer match to real a development
    workflow. An effect of this is that we can see the essential configs more clearly (e.g. `spark-defaults.conf). 


[rest-spec]: https://github.com/apache/iceberg/blob/master/open-api/rest-catalog-open-api.yaml
[quickstart]: https://iceberg.apache.org/spark-quickstart
