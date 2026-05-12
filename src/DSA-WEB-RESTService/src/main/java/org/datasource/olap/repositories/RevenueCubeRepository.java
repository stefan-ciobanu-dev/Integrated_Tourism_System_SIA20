package org.datasource.olap.repositories;

import org.datasource.olap.entities.RevenueCubeEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;

public interface RevenueCubeRepository extends JpaRepository<RevenueCubeEntity, Long> {
	@Query("SELECT o FROM RevenueCubeEntity o")
	List<RevenueCubeEntity> queryAll();
}
