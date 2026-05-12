package org.datasource.csv.views.airline;

import org.datasource.csv.CSVResourceFileDataSourceConnector;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

@Service
public class AirlineViewBuilder {

	private static final String CSV_PATH = "datasource/CTG_AIRLINES.csv";

	protected List<AirlineView> viewList = new ArrayList<>();

	public List<AirlineView> getViewList() { return viewList; }

	public AirlineViewBuilder build() {
		List<String[]> rows = csvConnector.loadCSV(CSV_PATH);
		viewList = new ArrayList<>();
		for (String[] row : rows) {
			if (row.length >= 7) {
				viewList.add(new AirlineView(
					row[0].trim(), row[1].trim(), row[2].trim(),
					Integer.parseInt(row[3].trim()),
					Integer.parseInt(row[4].trim()),
					row[5].trim(), row[6].trim()
				));
			}
		}
		return this;
	}

	protected CSVResourceFileDataSourceConnector csvConnector;

	public AirlineViewBuilder(CSVResourceFileDataSourceConnector csvConnector) {
		this.csvConnector = csvConnector;
	}
}
