package org.datasource.csv.views.route;

import org.datasource.csv.CSVResourceFileDataSourceConnector;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

@Service
public class RouteViewBuilder {

	private static final String CSV_PATH = "datasource/DS2_ROUTES.csv";

	protected List<RouteView> viewList = new ArrayList<>();

	public List<RouteView> getViewList() { return viewList; }

	public RouteViewBuilder build() {
		List<String[]> rows = csvConnector.loadCSV(CSV_PATH);
		viewList = new ArrayList<>();
		for (String[] row : rows) {
			if (row.length >= 7) {
				viewList.add(new RouteView(
					row[0].trim(), row[1].trim(), row[2].trim(),
					Integer.parseInt(row[3].trim()),
					Integer.parseInt(row[4].trim()),
					Integer.parseInt(row[5].trim()),
					row[6].trim()
				));
			}
		}
		return this;
	}

	protected CSVResourceFileDataSourceConnector csvConnector;

	public RouteViewBuilder(CSVResourceFileDataSourceConnector csvConnector) {
		this.csvConnector = csvConnector;
	}
}
