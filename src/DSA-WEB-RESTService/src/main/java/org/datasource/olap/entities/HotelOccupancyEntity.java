package org.datasource.olap.entities;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.Immutable;

@Entity @Immutable
@Table(name = "OLAP_HOTEL_OCCUPANCY")
@Data
public class HotelOccupancyEntity {
	@Id
	@Column(name = "hotel_name")
	private String hotelName;

	@Column(name = "city")
	private String city;

	@Column(name = "country")
	private String country;

	@Column(name = "star_rating")
	private Integer starRating;

	@Column(name = "total_bookings")
	private Integer totalBookings;

	@Column(name = "total_revenue_eur")
	private Double totalRevenueEur;

	@Column(name = "avg_price_per_night")
	private Double avgPricePerNight;
}
