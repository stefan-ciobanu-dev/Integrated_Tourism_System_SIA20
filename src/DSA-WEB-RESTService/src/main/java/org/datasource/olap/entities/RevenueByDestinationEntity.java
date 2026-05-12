package org.datasource.olap.entities;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.Immutable;

@Entity @Immutable
@Table(name = "OLAP_REVENUE_BY_DESTINATION")
@Data
public class RevenueByDestinationEntity {
	@Id
	@Column(name = "destination")
	private String destination;

	@Column(name = "total_bookings")
	private Integer totalBookings;

	@Column(name = "total_revenue_eur")
	private Double totalRevenueEur;

	@Column(name = "avg_revenue_eur")
	private Double avgRevenueEur;

	@Column(name = "avg_duration_days")
	private Double avgDurationDays;
}
