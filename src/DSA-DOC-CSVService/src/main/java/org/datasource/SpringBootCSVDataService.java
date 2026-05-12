package org.datasource;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.web.servlet.support.SpringBootServletInitializer;
import org.springframework.context.annotation.Bean;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import java.util.logging.Logger;

@SpringBootApplication
public class SpringBootCSVDataService extends SpringBootServletInitializer {
	private static Logger logger = Logger.getLogger(SpringBootCSVDataService.class.getName());

	public static void main(String[] args) {
		logger.info("Loading ... DSA-DOC-CSVService Tourism CSV ...");
		SpringApplication.run(SpringBootCSVDataService.class, args);
	}

	@Bean
	public WebMvcConfigurer corsConfigurer() {
		return new WebMvcConfigurer() {
			@Override
			public void addCorsMappings(CorsRegistry registry) {
				registry.addMapping("/**")
					.allowedOrigins("*")
					.allowedMethods("GET", "POST", "OPTIONS")
					.allowedHeaders("*");
			}
		};
	}
}
