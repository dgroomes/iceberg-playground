# iceberg-playground

📚 Learning and exploring Apache Iceberg.


## Standalone subprojects

This repository illustrates different concepts, patterns and examples via standalone subprojects. Each subproject is
completely independent of the others and do not depend on the root project. This _standalone subproject constraint_
forces the subprojects to be complete and maximizes the reader's chances of successfully running, understanding, and
re-using the code.

The subprojects include:


### `write-and-read/`

Write to and read from an Iceberg table using the core Iceberg Java APIs.

See the README in [write-and-read/](write-and-read/).


### `spark-shell/`

Create and interact with Apache Iceberg tables from Spark shell.

See the README in [spark-shell/](spark-shell/).
