package org.datasource.csv.views.flight;

import org.datasource.csv.CSVResourceFileDataSourceConnector;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

@Service
public class FlightViewBuilder {

	private static final String CSV_PATH = "datasource/DS2_FLIGHTS.csv";

	protected List<FlightView> viewList = new ArrayList<>();

	public List<FlightView> getViewList() { return viewList; }

	public FlightViewBuilder build() {
		List<String[]> rows = csvConnector.loadCSV(CSV_PATH);
		viewList = new ArrayList<>();
		for (String[] row : rows) {
			if (row.length >= 14) {
				viewList.add(new FlightView(
					row[0].trim(), row[1].trim(), row[2].trim(), row[3].trim(),
					row[4].trim(), row[5].trim(),
					Integer.parseInt(row[6].trim()),
					row[7].trim(),
					Integer.parseInt(row[8].trim()),
					Integer.parseInt(row[9].trim()),
					Double.parseDouble(row[10].trim()),
					Double.parseDouble(row[11].trim()),
					row[12].trim(), row[13].trim()
				));
			}
		}
		return this;
	}

	protected CSVResourceFileDataSourceConnector csvConnector;

	public FlightViewBuilder(CSVResourceFileDataSourceConnector csvConnector) {
		this.csvConnector = csvConnector;
	}
}
