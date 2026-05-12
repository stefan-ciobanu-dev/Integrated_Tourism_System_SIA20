package org.datasource.mongo.views.booking;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data @AllArgsConstructor @NoArgsConstructor(force = true)
@JsonIgnoreProperties({"_id"})
public class MongoBookingView {
	private String bookingId;
	private String bookingDate;
	private String guestFirstName;
	private String guestLastName;
	private String guestEmail;
	private String guestCountry;
	private String guestAgeGroup;
	private String destination;
	private String travelType;
	private String startDate;
	private String endDate;
	private Integer durationDays;
	private Double subtotalEur;
	private Double taxRate;
	private Double taxAmount;
	private Double totalEur;
	private String paymentStatus;
	private String paymentDate;
	private String agentId;
}
