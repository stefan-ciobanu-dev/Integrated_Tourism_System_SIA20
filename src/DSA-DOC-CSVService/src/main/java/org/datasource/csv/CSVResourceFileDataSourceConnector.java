package org.datasource.csv;

import org.springframework.stereotype.Service;
import org.springframework.web.context.annotation.ApplicationScope;

import java.io.BufferedReader;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Logger;

@Service @ApplicationScope
public class CSVResourceFileDataSourceConnector {
	private static Logger logger = Logger.getLogger(CSVResourceFileDataSourceConnector.class.getName());

	public List<String[]> loadCSV(String resourcePath) {
		List<String[]> records = new ArrayList<>();
		try {
			InputStream inputStream = getClass().getClassLoader().getResourceAsStream(resourcePath);
			if (inputStream == null) {
				logger.warning("CSV resource not found: " + resourcePath);
				return records;
			}
			BufferedReader reader = new BufferedReader(new InputStreamReader(inputStream, StandardCharsets.UTF_8));
			String line;
			boolean isHeader = true;
			while ((line = reader.readLine()) != null) {
				if (isHeader) { isHeader = false; continue; }
				if (line.trim().isEmpty()) continue;
				records.add(line.split(",", -1));
			}
			reader.close();
			logger.info("CSV loaded: " + resourcePath + " -> " + records.size() + " records");
		} catch (Exception e) {
			logger.severe("Error loading CSV " + resourcePath + ": " + e.getMessage());
		}
		return records;
	}
}
