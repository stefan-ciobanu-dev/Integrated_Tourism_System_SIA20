package org.datasource.jpa.views.hotel;

import org.datasource.jpa.JPADataSourceConnector;
import org.springframework.stereotype.Service;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

@Service
public class HotelViewBuilder {

	private String SQL_SELECT = """
		SELECT h.hotel_id, h.name, h.star_rating, h.city,
			   h.country, h.capacity, h.price_per_night
		FROM tourism.hotels h
		ORDER BY h.hotel_id
	""";

	protected List<HotelView> viewList = new ArrayList<>();

	public List<HotelView> getViewList() {
		return viewList;
	}

	public HotelViewBuilder build() {
		return this.select();
	}

	protected HotelViewBuilder select() {
		EntityManager em = dataSourceConnector.getEntityManager();
		Query query = em.createNativeQuery(SQL_SELECT);
		List<Object[]> rows = query.getResultList();
		viewList = new ArrayList<>();
		for (Object[] row : rows) {
			viewList.add(new HotelView(
				((Number) row[0]).longValue(),
				(String) row[1],
				((Number) row[2]).intValue(),
				(String) row[3],
				(String) row[4],
				row[5] != null ? ((Number) row[5]).intValue() : null,
				row[6] != null ? (BigDecimal) row[6] : null
			));
		}
		return this;
	}

	protected JPADataSourceConnector dataSourceConnector;

	public HotelViewBuilder(JPADataSourceConnector dataSourceConnector) {
		this.dataSourceConnector = dataSourceConnector;
	}
}
