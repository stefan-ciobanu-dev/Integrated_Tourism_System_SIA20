package org.datasource.jpa.views.hotel;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data @AllArgsConstructor @NoArgsConstructor(force = true)
public class HotelView {
	private Long hotelId;
	private String name;
	private Integer starRating;
	private String city;
	private String country;
	private Integer capacity;
	private BigDecimal pricePerNight;
}
