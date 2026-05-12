package org.datasource.csv.views.period;

import org.datasource.csv.CSVResourceFileDataSourceConnector;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

@Service
public class PeriodViewBuilder {

	private static final String CSV_PATH = "datasource/Periods_Tourism.csv";

	protected List<PeriodView> viewList = new ArrayList<>();

	public List<PeriodView> getViewList() { return viewList; }

	public PeriodViewBuilder build() {
		List<String[]> rows = csvConnector.loadCSV(CSV_PATH);
		viewList = new ArrayList<>();
		for (String[] row : rows) {
			if (row.length >= 7) {
				viewList.add(new PeriodView(
					row[0].trim(),
					Integer.parseInt(row[1].trim()),
					Integer.parseInt(row[2].trim()),
					Integer.parseInt(row[3].trim()),
					Integer.parseInt(row[4].trim()),
					row[5].trim(), row[6].trim()
				));
			}
		}
		return this;
	}

	protected CSVResourceFileDataSourceConnector csvConnector;

	public PeriodViewBuilder(CSVResourceFileDataSourceConnector csvConnector) {
		this.csvConnector = csvConnector;
	}
}
