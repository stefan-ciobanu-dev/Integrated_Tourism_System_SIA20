package org.spark.service.rest;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;

/**
 * Static utility class used by Spark SQL java_method() UDF to call external REST data services.
 * Called as: java_method('org.spark.service.rest.QueryRESTDataService', 'getRESTDataDocument', url)
 */
public class QueryRESTDataService {

    public static String getRESTDataDocument(String serviceURL) {
        try {
            URL obj = new URL(serviceURL);
            HttpURLConnection con = (HttpURLConnection) obj.openConnection();
            con.setRequestMethod("GET");
            con.setRequestProperty("Accept", "application/json");
            con.setConnectTimeout(30000);
            con.setReadTimeout(60000);
            int responseCode = con.getResponseCode();
            if (responseCode != 200) {
                return "[]";
            }
            BufferedReader in = new BufferedReader(new InputStreamReader(con.getInputStream()));
            StringBuilder response = new StringBuilder();
            String line;
            while ((line = in.readLine()) != null) {
                response.append(line);
            }
            in.close();
            return response.toString();
        } catch (Exception e) {
            return "[]";
        }
    }
}
