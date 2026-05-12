package org.datasource.jpa.views.tourist;

import org.datasource.jpa.JPADataSourceConnector;
import org.springframework.stereotype.Service;

import jakarta.persistence.*;
import java.util.ArrayList;
import java.util.List;

@Service
public class TouristViewBuilder {

	private String SQL_SELECT = """
		SELECT t.tourist_id, t.first_name, t.last_name, t.email,
			   t.country, t.birth_date, t.registration_date
		FROM tourism.tourists t
		ORDER BY t.tourist_id
	""";

	protected List<TouristView> viewList = new ArrayList<>();

	public List<TouristView> getViewList() {
		return viewList;
	}

	public TouristViewBuilder build() {
		return this.select();
	}

	protected TouristViewBuilder select() {
		EntityManager em = dataSourceConnector.getEntityManager();
		Query query = em.createNativeQuery(SQL_SELECT);
		List<Object[]> rows = query.getResultList();
		viewList = new ArrayList<>();
		for (Object[] row : rows) {
			viewList.add(new TouristView(
				((Number) row[0]).longValue(),
				(String) row[1],
				(String) row[2],
				(String) row[3],
				(String) row[4],
				row[5] != null ? ((java.sql.Date) row[5]).toLocalDate() : null,
				row[6] != null ? ((java.sql.Date) row[6]).toLocalDate() : null
			));
		}
		return this;
	}

	protected JPADataSourceConnector dataSourceConnector;

	public TouristViewBuilder(JPADataSourceConnector dataSourceConnector) {
		this.dataSourceConnector = dataSourceConnector;
	}
}
