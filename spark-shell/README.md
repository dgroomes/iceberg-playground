# spark-shell

Create and interact with Apache Iceberg tables from Spark shell.


## Instructions

Follow these instructions to create a table, write to it, and read from it.

1. Pre-requisite: Java
    * I'm using Java 21
2. Pre-requisite: Spark
    * I'm using Spark 3.5.x installed with Homebrew
3. Start a Spark shell session:
    * ```shell
      SPARK_CONF_DIR=. SPARK_LOCAL_IP=127.0.0.1 spark-shell --packages org.apache.iceberg:iceberg-spark-runtime-3.5_2.12:1.8.1
      ```
4. Define an Iceberg table:
    * ```scala
      spark.sql("""
          create table messages (
              id int,
              message string
          )
          using iceberg
      """)
      ```
5. Write some sample data:
    * ```scala
      spark.sql("""
          insert into messages values
              (1, 'Hello, world!'),
              (2, 'Spark was here!')
      """)
      ```
6. Read the data:
    * ```scala
      spark.sql("select * from messages order by id").show()
      ```
    * You should see the rows you inserted.
    * ```text
      +---+---------------+
      | id|        message|
      +---+---------------+
      |  1|  Hello, world!|
      |  2|Spark was here!|
      +---+---------------+
      ```
7. Evolve the schema by adding a column
    * ```scala
      spark.sql("alter table messages add column word_count int")
      ```
    * Now, insert a row and set the new column.
    * ```scala
      val msg = "Iceberg is neat!"
      val wordCount = msg.split(" ").length
      
      spark.sql("insert into messages values (3, ?, ?)", Array(msg, wordCount))
      ```
    * Now, read the data again.
    * ```scala
      spark.sql("select * from messages order by id").show()
      ```
    * ```text
      +---+----------------+----------+
      | id|         message|word_count|
      +---+----------------+----------+
      |  1|   Hello, world!|      NULL|
      |  2| Spark was here!|      NULL|
      |  3|Iceberg is neat!|         3|
      +---+----------------+----------+```
    * Notice the new row and how it includes a value for the `word_count` column.
8. When you're done, quit the Spark shell:
    * ```scala
      :quit
      ```
