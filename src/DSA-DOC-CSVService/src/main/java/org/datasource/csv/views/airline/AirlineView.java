package org.datasource.csv.views.airline;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data @AllArgsConstructor @NoArgsConstructor(force = true)
public class AirlineView {
	private String airlineCode;
	private String airlineName;
	private String country;
	private Integer fleetSize;
	private Integer foundedYear;
	private String alliance;
	private String website;
}
