package org.datasource.csv.views.flight;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data @AllArgsConstructor @NoArgsConstructor(force = true)
public class FlightView {
	private String flightId;
	private String airline;
	private String departureCity;
	private String arrivalCity;
	private String departureTime;
	private String arrivalTime;
	private Integer flightDuration;
	private String aircraftType;
	private Integer capacity;
	private Integer seatsAvailable;
	private Double economyPrice;
	private Double businessPrice;
	private String daysOperating;
	private String operatingPeriod;
}
