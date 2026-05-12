package org.datasource.mongo.views.currency;

import com.mongodb.client.MongoCollection;
import org.bson.Document;
import org.datasource.mongo.MongoDataSourceConnector;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

@Service
public class CurrencyViewBuilder {

	protected List<CurrencyView> viewList = new ArrayList<>();

	public List<CurrencyView> getViewList() { return viewList; }

	public CurrencyViewBuilder build() {
		MongoCollection<Document> collection = mongoConnector.getDatabase().getCollection("currencies");
		viewList = new ArrayList<>();
		for (Document doc : collection.find()) {
			String baseCurrency = doc.getString("base_currency");
			String extractionDate = doc.getString("extraction_date");
			List<Document> rates = doc.getList("rates", Document.class);
			if (rates != null) {
				for (Document rate : rates) {
					viewList.add(new CurrencyView(
						rate.getString("currency_code"),
						rate.getString("currency_name"),
						toDouble(rate.get("exchange_rate")),
						rate.getString("region"),
						rate.getString("symbol"),
						baseCurrency,
						extractionDate
					));
				}
			}
		}
		return this;
	}

	private Double toDouble(Object val) {
		if (val == null) return null;
		if (val instanceof Number) return ((Number) val).doubleValue();
		return Double.parseDouble(val.toString());
	}

	protected MongoDataSourceConnector mongoConnector;

	public CurrencyViewBuilder(MongoDataSourceConnector mongoConnector) {
		this.mongoConnector = mongoConnector;
	}
}
