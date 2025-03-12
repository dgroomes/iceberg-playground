# rest-catalog
NOT YET FULLY IMPLEMENTED (AI sloppy)

Use the Iceberg REST catalog as an authoritative source for table metadata and operations.


## Overview

This project demonstrates using Spark with the Iceberg REST catalog.

The Iceberg REST catalog follows the open REST catalog specification, making it accessible from any client that supports
this protocol. In this example, we'll use Spark shell running on the host machine to connect to a REST catalog service
running in a Docker container.

This approach is particularly useful in multi-engine environments where you want consistent table access and management
across different processing engines.


## Instructions

Follow these instructions to create and interact with Iceberg tables using the REST catalog.

1. Pre-requisite: Java
    * I'm using Java 21
2. Pre-requisite: Spark
    * I'm using Spark 3.5.x installed with Homebrew
3. Pre-requisite: Docker and Docker Compose
    * For running the Iceberg REST catalog service
4. Start the REST catalog service:
    * ```shell
      docker-compose up -d
      ```
5. Start a Spark shell session configured to use the REST catalog:
    * ```shell
      SPARK_CONF_DIR=. SPARK_LOCAL_IP=127.0.0.1 spark-shell --packages org.apache.iceberg:iceberg-spark-runtime-3.5_2.12:1.8.1
      ```
6. Define a table using the REST catalog:
    * ```scala
      spark.sql("""
          create table rest.db.messages (
              id int,
              message string
          )
          using iceberg
      """)
      ```
7. Write some sample data:
    * ```scala
      spark.sql("""
          insert into rest.db.messages values
              (1, 'Hello REST catalog!'),
              (2, 'Iceberg + REST API is powerful!')
      """)
      ```
    * Where did the data go?
8. Read the data:
    * ```scala
      spark.sql("select * from rest.db.messages order by id").show()
      ```
9. Check the table metadata:
    * ```scala
      spark.sql("select * from rest.db.messages.snapshots").show(truncate=false)
      ```
    * TODO: This fails with `org.apache.iceberg.exceptions.NotFoundException: File does not exist: file:/tmp/warehouse/db/messages/metadata/00001-85287983-12c2-49eb-ad8b-7c25be440fd0.metadata.json`
    * This will show you information about the snapshots for this table.
    * ```scala
      // Access metadata through the REST API
      spark.sql("select * from rest.db.messages.history").show(truncate=false)
      ```
    * It's interesting that these fail because how are you supposed to do this? The catalog server is storing stuff in
      its own filesystem. Hmmm.
10. When you're done, quit the Spark shell:
    * ```scala
      :quit
      ```
11. Stop the Docker container:
    * ```shell
      docker-compose down
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

For a complete list of REST API endpoints, see the [Iceberg REST API Specification](https://github.com/apache/iceberg/blob/master/open-api/rest-catalog-open-api.yaml).

## Wish List

General clean-ups, TODOs and things I wish to implement for this subproject:

* [x] Showcase using the REST API to show the table metadata (added curl examples)
