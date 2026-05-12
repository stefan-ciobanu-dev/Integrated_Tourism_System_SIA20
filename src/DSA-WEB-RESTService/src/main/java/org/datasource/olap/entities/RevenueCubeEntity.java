package org.datasource.olap.entities;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.Immutable;

@Entity @Immutable
@Table(name = "OLAP_REVENUE_CUBE")
@Data
public class RevenueCubeEntity {
	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	@Column(name = "row_id")
	private Long rowId;

	@Column(name = "destination")
	private String destination;

	@Column(name = "travel_type")
	private String travelType;

	@Column(name = "guest_country")
	private String guestCountry;

	@Column(name = "total_bookings")
	private Integer totalBookings;

	@Column(name = "total_revenue_eur")
	private Double totalRevenueEur;

	@Column(name = "avg_revenue_eur")
	private Double avgRevenueEur;
}
