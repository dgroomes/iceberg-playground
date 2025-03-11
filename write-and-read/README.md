# write-and-read

Write to and read from an Iceberg table using the core Iceberg Java APIs.


## Overview

This is a "hello world"-style example of Apache Iceberg. It's designed to get you acquainted with Iceberg by
demonstrating core operations in a table-based data system: defining a table, writing data to it, and reading data from
it.

With foundational examples, I prefer to omit as much incidental complexity as possible. But, because Iceberg is only a
piece of middleware in a broader data system, we need to bring in some external dependencies to flesh out a runnable
program. In particular, let's bring in Apache Parquet.

> Iceberg is to Parquet as a **table format** is to a **file format**

Unfortunately, Iceberg's integration with Parquet [co-mingles with Hadoop dependencies](https://github.com/apache/iceberg/blob/abb47830e7df7dc2ae93c74b0ad97f06cdd37aad/parquet/src/main/java/org/apache/iceberg/parquet/Parquet.java#L63)
so we have to bring those in as well.

Unfortunately again, it's turtles all the way down because even Parquet is not a complete protein. We need to bring in
Apache Avro or something (I really don't want to bring in Avro) as the actual serialization tech (? I'm not really sure,
I'm surprised it's come to this). Parquet/Iceberg has a "generic" concept and we can bring in `org.apache.parquet:parquet-column`
to make it work. We're using `GenericParquetWriter.java` in `iceberg-parquet` which [imports `org.apache.parquet.schema.MessageType`](https://github.com/apache/iceberg/blob/71493b92dc2e0b953c184f76ad76e7f8794da8b1/parquet/src/main/java/org/apache/iceberg/data/parquet/GenericParquetWriter.java#L36)
which is in the [`parquet-column` library](https://github.com/apache/parquet-java/blob/92354f6be7ee3b5930c82408102b10a6b2b5f3c2/parquet-column/src/main/java/org/apache/parquet/schema/MessageType.java#L29).
This library does not come by default, with `iceberg-parquet`. If I omit it, I get a compile error:

```text
src/main/java/dgroomes/write_and_read/Main.java:58: error: cannot access MessageType
                .createWriterFunc(GenericParquetWriter::buildWriter)
                ^
  class file for org.apache.parquet.schema.MessageType not found
```


## Instructions

Follow these instructions to build and run the program.

1. Pre-requisite: Java 21
2. Build the program distribution:
    * ```shell
      ./gradlew install
      ```
3. Run the `write-and-read` subproject:
    * ```shell
      ./build/install/write-and-read/bin/write-and-read
      ```
4. Study the output
    * The program output will look something like this:
    * ```text
      3 records written to table: person_table
      3 records read from table: person_table
      
      > ID: 1, Name: Alice, Department: Engineering
      > ID: 2, Name: Bob,   Department: Marketing
      > ID: 3, Name: Carol, Department: Sales
      ```


## Wish List

General clean-ups, TODOs and things I wish to implement for this subproject:

* [x] Scaffold the subproject
* [ ] Add a "delete" operation
* [ ] Add a "update" operation
