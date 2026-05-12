package org.datasource;

import org.datasource.olap.entities.*;
import org.datasource.olap.repositories.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.logging.Logger;

/*	REST Service URL
	http://localhost:8096/DSA-WEB-RESTService/rest/olap/RevenueByDestination
	http://localhost:8096/DSA-WEB-RESTService/rest/olap/RevenueByTravelType
	http://localhost:8096/DSA-WEB-RESTService/rest/olap/RevenueCube
	http://localhost:8096/DSA-WEB-RESTService/rest/olap/HotelOccupancy
*/
@RestController
@RequestMapping("/olap")
public class RESTViewServiceOLAP {
	private static Logger logger = Logger.getLogger(RESTViewServiceOLAP.class.getName());

	@RequestMapping(value = "/ping", method = RequestMethod.GET,
			produces = {MediaType.TEXT_PLAIN_VALUE})
	@ResponseBody
	public String pingDataSource() {
		logger.info(">>>> DSA-WEB-RESTService:: RESTViewService is Up!");
		return "Ping response from DSA-WEB-RESTService!";
	}

	@RequestMapping(value = "/RevenueByDestination", method = RequestMethod.GET,
			produces = {MediaType.APPLICATION_JSON_VALUE, MediaType.APPLICATION_XML_VALUE})
	@ResponseBody
	public List<RevenueByDestinationEntity> get_RevenueByDestination() {
		return revenueByDestinationRepository.queryAll();
	}

	@RequestMapping(value = "/RevenueByTravelType", method = RequestMethod.GET,
			produces = {MediaType.APPLICATION_JSON_VALUE, MediaType.APPLICATION_XML_VALUE})
	@ResponseBody
	public List<RevenueByTravelTypeEntity> get_RevenueByTravelType() {
		return revenueByTravelTypeRepository.queryAll();
	}

	@RequestMapping(value = "/RevenueCube", method = RequestMethod.GET,
			produces = {MediaType.APPLICATION_JSON_VALUE, MediaType.APPLICATION_XML_VALUE})
	@ResponseBody
	public List<RevenueCubeEntity> get_RevenueCube() {
		return revenueCubeRepository.queryAll();
	}

	@RequestMapping(value = "/HotelOccupancy", method = RequestMethod.GET,
			produces = {MediaType.APPLICATION_JSON_VALUE, MediaType.APPLICATION_XML_VALUE})
	@ResponseBody
	public List<HotelOccupancyEntity> get_HotelOccupancy() {
		return hotelOccupancyRepository.queryAll();
	}

	// Set-up
	@Autowired private RevenueByDestinationRepository revenueByDestinationRepository;
	@Autowired private RevenueByTravelTypeRepository revenueByTravelTypeRepository;
	@Autowired private RevenueCubeRepository revenueCubeRepository;
	@Autowired private HotelOccupancyRepository hotelOccupancyRepository;
}
