package org.datasource.csv.views.hotelstars;

import org.datasource.csv.CSVResourceFileDataSourceConnector;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

@Service
public class HotelStarsViewBuilder {

	private static final String CSV_PATH = "datasource/CTG_HOTEL_STARS.csv";

	protected List<HotelStarsView> viewList = new ArrayList<>();

	public List<HotelStarsView> getViewList() { return viewList; }

	public HotelStarsViewBuilder build() {
		List<String[]> rows = csvConnector.loadCSV(CSV_PATH);
		viewList = new ArrayList<>();
		for (String[] row : rows) {
			if (row.length >= 3) {
				viewList.add(new HotelStarsView(
					Integer.parseInt(row[0].trim()),
					row[1].trim(), row[2].trim()
				));
			}
		}
		return this;
	}

	protected CSVResourceFileDataSourceConnector csvConnector;

	public HotelStarsViewBuilder(CSVResourceFileDataSourceConnector csvConnector) {
		this.csvConnector = csvConnector;
	}
}
