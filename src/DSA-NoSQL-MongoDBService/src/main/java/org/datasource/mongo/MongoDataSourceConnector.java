package org.datasource.mongo;

import com.mongodb.client.MongoClient;
import com.mongodb.client.MongoClients;
import com.mongodb.client.MongoDatabase;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.context.annotation.ApplicationScope;

import java.util.logging.Logger;

@Service @ApplicationScope
public class MongoDataSourceConnector {
	private static Logger logger = Logger.getLogger(MongoDataSourceConnector.class.getName());

	@Value("${spring.data.mongodb.uri}")
	private String mongoUri;

	private MongoClient mongoClient;
	private MongoDatabase database;

	public MongoDatabase getDatabase() {
		if (database == null) {
			mongoClient = MongoClients.create(mongoUri);
			database = mongoClient.getDatabase("tourism_data");
			logger.info("MongoDB connected to tourism_data");
		}
		return database;
	}
}
