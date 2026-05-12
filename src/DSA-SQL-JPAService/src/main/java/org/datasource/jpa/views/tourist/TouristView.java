package org.datasource.jpa.views.tourist;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

@Data @AllArgsConstructor @NoArgsConstructor(force = true)
public class TouristView {
	private Long touristId;
	private String firstName;
	private String lastName;
	private String email;
	private String country;
	private LocalDate birthDate;
	private LocalDate registrationDate;
}
