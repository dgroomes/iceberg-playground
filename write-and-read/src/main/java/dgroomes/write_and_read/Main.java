package dgroomes.write_and_read;

import org.apache.hadoop.conf.Configuration;
import org.apache.iceberg.*;
import org.apache.iceberg.catalog.TableIdentifier;
import org.apache.iceberg.data.GenericAppenderFactory;
import org.apache.iceberg.data.GenericRecord;
import org.apache.iceberg.data.IcebergGenerics;
import org.apache.iceberg.data.Record;
import org.apache.iceberg.hadoop.HadoopCatalog;
import org.apache.iceberg.io.OutputFileFactory;
import org.apache.iceberg.io.UnpartitionedWriter;
import org.apache.iceberg.io.WriteResult;
import org.apache.iceberg.types.Types.IntegerType;
import org.apache.iceberg.types.Types.NestedField;
import org.apache.iceberg.types.Types.StringType;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

public class Main {

    private static final Logger log = LoggerFactory.getLogger("app");

    public static void main(String[] args) throws IOException {
        var dir = Paths.get(".").toAbsolutePath().normalize();
        if (!"write-and-read".equals(dir.getFileName().toString())) {
            var msg = "This program must be run from its project directory ('write-and-read') but was run from '%s'".formatted(dir);
            throw new IllegalStateException(msg);
        }

        var tf = dir.resolve("warehouse/default/observations/observations.parquet");
        if (java.nio.file.Files.exists(tf)) {
            java.nio.file.Files.delete(tf);
            log.info("Deleted existing table file: {}", tf);
        }

        Configuration conf = new Configuration(); // Can I get away without using a catalog? The InMemory one was annoying
        HadoopCatalog catalog = new HadoopCatalog(conf, dir.resolve("warehouse").toString());
        var tableId = TableIdentifier.parse("default.observations");
        var schema = new Schema(
                NestedField.required(1, "id", IntegerType.get(), "Generated unique identifier"),
                NestedField.required(2, "observation", StringType.get(), "An observation about the world")
        );

        if (catalog.tableExists(tableId)) {
            log.info("Table '{}' already exists. Deleting it...", tableId);
            catalog.dropTable(tableId, true);
        }
        Table table = catalog.createTable(tableId, schema);
        log.info("Created {} table", table);

        log.info("Using table location: {}", table.location());
        log.info("Using table name: {}", table.name());
        log.info("Using table schema: {}", table.schema());
        log.info("Using table partition spec: {}", table.spec());

        log.info("Writing rows to the table '{}'...", tableId);
        Record record = GenericRecord.create(schema.asStruct());
        var records = List.of(
                record.copy(Map.of("id", 1, "observation", "The sky is blue")),
                record.copy(Map.of("id", 2, "observation", "The speed of light can circle the earth 7 times in a second"))
        );

        var appenderFactory = new GenericAppenderFactory(table.schema());
        var fileFactory = OutputFileFactory.builderFor(table, 0, 0).build();

        WriteResult result;
        try (var writer = new UnpartitionedWriter<>(table.spec(), FileFormat.PARQUET, appenderFactory, fileFactory, table.io(), TableProperties.WRITE_TARGET_FILE_SIZE_BYTES_DEFAULT)) {
            for (var r : records) writer.write(r);
            result = writer.complete();
        } catch (IOException e) {
            log.error("Error writing records to table", e);
            return;
        }

        var append = table.newAppend();
        for (var file : result.dataFiles()) append.appendFile(file);
        append.commit(); // In a real scenario, you need to catch an exception in case the commit failed.

        log.info("Wrote {} rows to the table", records.size());

        log.info("Reading rows from the table...");
        var rows = new ArrayList<Record>();
        try (var scan = IcebergGenerics.read(table).build()) {
            scan.forEach(rows::add);
        }

        log.info("{} rows read from the table", rows.size());
        for (var row : rows) {
            log.info("Row: {}", row);
        }
    }
}
