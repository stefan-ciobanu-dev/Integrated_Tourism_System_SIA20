package org.datasource.olap.entities;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.Immutable;

@Entity @Immutable
@Table(name = "OLAP_REVENUE_BY_TRAVEL_TYPE")
@Data
public class RevenueByTravelTypeEntity {
	@Id
	@Column(name = "travel_type")
	private String travelType;

	@Column(name = "total_bookings")
	private Integer totalBookings;

	@Column(name = "total_revenue_eur")
	private Double totalRevenueEur;

	@Column(name = "avg_revenue_eur")
	private Double avgRevenueEur;
}
