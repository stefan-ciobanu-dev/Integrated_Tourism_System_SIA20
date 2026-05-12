package org.datasource.jpa.views.booking;

import org.datasource.jpa.JPADataSourceConnector;
import org.springframework.stereotype.Service;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

@Service
public class BookingViewBuilder {

	private String SQL_SELECT = """
		SELECT b.booking_id, b.tourist_id, b.hotel_id,
			   b.check_in_date, b.check_out_date, b.num_guests,
			   b.total_amount, b.booking_status, b.booking_date
		FROM tourism.bookings b
		ORDER BY b.booking_id
	""";

	protected List<BookingView> viewList = new ArrayList<>();

	public List<BookingView> getViewList() {
		return viewList;
	}

	public BookingViewBuilder build() {
		return this.select();
	}

	protected BookingViewBuilder select() {
		EntityManager em = dataSourceConnector.getEntityManager();
		Query query = em.createNativeQuery(SQL_SELECT);
		List<Object[]> rows = query.getResultList();
		viewList = new ArrayList<>();
		for (Object[] row : rows) {
			viewList.add(new BookingView(
				((Number) row[0]).longValue(),
				((Number) row[1]).longValue(),
				((Number) row[2]).longValue(),
				row[3] != null ? ((java.sql.Date) row[3]).toLocalDate() : null,
				row[4] != null ? ((java.sql.Date) row[4]).toLocalDate() : null,
				row[5] != null ? ((Number) row[5]).intValue() : null,
				row[6] != null ? (BigDecimal) row[6] : null,
				(String) row[7],
				row[8] != null ? ((java.sql.Date) row[8]).toLocalDate() : null
			));
		}
		return this;
	}

	protected JPADataSourceConnector dataSourceConnector;

	public BookingViewBuilder(JPADataSourceConnector dataSourceConnector) {
		this.dataSourceConnector = dataSourceConnector;
	}
}
