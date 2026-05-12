package org.datasource.jpa.views.booking;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;

@Data @AllArgsConstructor @NoArgsConstructor(force = true)
public class BookingView {
	private Long bookingId;
	private Long touristId;
	private Long hotelId;
	private LocalDate checkInDate;
	private LocalDate checkOutDate;
	private Integer numGuests;
	private BigDecimal totalAmount;
	private String bookingStatus;
	private LocalDate bookingDate;
}
