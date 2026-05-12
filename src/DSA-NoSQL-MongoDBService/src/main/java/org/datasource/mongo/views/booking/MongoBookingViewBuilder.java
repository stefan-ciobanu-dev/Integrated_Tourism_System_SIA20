package org.datasource.mongo.views.booking;

import com.mongodb.client.MongoCollection;
import org.bson.Document;
import org.datasource.mongo.MongoDataSourceConnector;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

@Service
public class MongoBookingViewBuilder {

	protected List<MongoBookingView> viewList = new ArrayList<>();

	public List<MongoBookingView> getViewList() { return viewList; }

	public MongoBookingViewBuilder build() {
		MongoCollection<Document> collection = mongoConnector.getDatabase().getCollection("bookings");
		viewList = new ArrayList<>();
		for (Document doc : collection.find()) {
			Document guest = doc.get("guest", Document.class);
			Document itinerary = doc.get("itinerary", Document.class);
			Document totals = doc.get("totals", Document.class);

			viewList.add(new MongoBookingView(
				doc.getString("booking_id"),
				doc.getString("booking_date"),
				guest != null ? guest.getString("first_name") : null,
				guest != null ? guest.getString("last_name") : null,
				guest != null ? guest.getString("email") : null,
				guest != null ? guest.getString("country_of_origin") : null,
				guest != null ? guest.getString("age_group") : null,
				itinerary != null ? itinerary.getString("destination") : null,
				itinerary != null ? itinerary.getString("travel_type") : null,
				itinerary != null ? itinerary.getString("start_date") : null,
				itinerary != null ? itinerary.getString("end_date") : null,
				itinerary != null ? itinerary.getInteger("duration_days") : null,
				totals != null ? toDouble(totals.get("subtotal_eur")) : null,
				totals != null ? toDouble(totals.get("tax_rate")) : null,
				totals != null ? toDouble(totals.get("tax_amount")) : null,
				totals != null ? toDouble(totals.get("total_eur")) : null,
				totals != null ? totals.getString("payment_status") : null,
				totals != null ? totals.getString("payment_date") : null,
				doc.getString("agent_id")
			));
		}
		return this;
	}

	private Double toDouble(Object val) {
		if (val == null) return null;
		if (val instanceof Number) return ((Number) val).doubleValue();
		return Double.parseDouble(val.toString());
	}

	protected MongoDataSourceConnector mongoConnector;

	public MongoBookingViewBuilder(MongoDataSourceConnector mongoConnector) {
		this.mongoConnector = mongoConnector;
	}
}
