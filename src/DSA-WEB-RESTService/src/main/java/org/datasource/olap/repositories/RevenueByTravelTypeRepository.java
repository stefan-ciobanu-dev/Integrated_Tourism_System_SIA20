package org.datasource.olap.repositories;

import org.datasource.olap.entities.RevenueByTravelTypeEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;

public interface RevenueByTravelTypeRepository extends JpaRepository<RevenueByTravelTypeEntity, String> {
	@Query("SELECT o FROM RevenueByTravelTypeEntity o")
	List<RevenueByTravelTypeEntity> queryAll();
}
