package org.datasource.olap.repositories;

import org.datasource.olap.entities.HotelOccupancyEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;

public interface HotelOccupancyRepository extends JpaRepository<HotelOccupancyEntity, String> {
	@Query("SELECT o FROM HotelOccupancyEntity o")
	List<HotelOccupancyEntity> queryAll();
}
