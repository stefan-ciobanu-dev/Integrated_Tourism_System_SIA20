package org.datasource.csv.views.touristage;

import org.datasource.csv.CSVResourceFileDataSourceConnector;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

@Service
public class TouristAgeViewBuilder {

	private static final String CSV_PATH = "datasource/CTG_TOURIST_AGE.csv";

	protected List<TouristAgeView> viewList = new ArrayList<>();

	public List<TouristAgeView> getViewList() { return viewList; }

	public TouristAgeViewBuilder build() {
		List<String[]> rows = csvConnector.loadCSV(CSV_PATH);
		viewList = new ArrayList<>();
		for (String[] row : rows) {
			if (row.length >= 3) {
				viewList.add(new TouristAgeView(
					Integer.parseInt(row[0].trim()),
					row[1].trim(), row[2].trim()
				));
			}
		}
		return this;
	}

	protected CSVResourceFileDataSourceConnector csvConnector;

	public TouristAgeViewBuilder(CSVResourceFileDataSourceConnector csvConnector) {
		this.csvConnector = csvConnector;
	}
}
