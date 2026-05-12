package org.datasource.csv.views.route;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data @AllArgsConstructor @NoArgsConstructor(force = true)
public class RouteView {
	private String routeId;
	private String departureCity;
	private String arrivalCity;
	private Integer distanceKm;
	private Integer frequencyPerWeek;
	private Integer averageFlightTime;
	private String routeType;
}
