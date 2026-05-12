package org.datasource.olap.repositories;

import org.datasource.olap.entities.RevenueByDestinationEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;

public interface RevenueByDestinationRepository extends JpaRepository<RevenueByDestinationEntity, String> {
	@Query("SELECT o FROM RevenueByDestinationEntity o")
	List<RevenueByDestinationEntity> queryAll();
}
