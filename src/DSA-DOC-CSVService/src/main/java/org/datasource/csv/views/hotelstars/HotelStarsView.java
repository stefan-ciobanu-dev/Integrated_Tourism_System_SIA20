package org.datasource.csv.views.hotelstars;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data @AllArgsConstructor @NoArgsConstructor(force = true)
public class HotelStarsView {
	private Integer starCategory;
	private String starLabel;
	private String description;
}
