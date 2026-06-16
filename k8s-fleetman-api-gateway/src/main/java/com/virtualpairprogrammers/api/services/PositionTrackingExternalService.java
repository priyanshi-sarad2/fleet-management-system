package com.virtualpairprogrammers.api.services;

import java.text.SimpleDateFormat;
import java.util.Collection;
import java.util.Date;
import java.util.HashSet;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.virtualpairprogrammers.api.domain.VehiclePosition;

import io.github.resilience4j.circuitbreaker.annotation.CircuitBreaker;

@Service 
public class PositionTrackingExternalService 
{
	@Autowired
	private RemotePositionMicroserviceCalls remoteService;
	
    private SimpleDateFormat formatter = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSZ");
	
	@CircuitBreaker(name="positionTracker", fallbackMethod="handleExternalServiceDown")
	public Collection<VehiclePosition> getAllUpdatedPositionsSince(Date since)
	{
		String date = formatter.format(since);
		return remoteService.getAllLatestPositionsSince(date);
	}
	
	public Collection<VehiclePosition> handleExternalServiceDown(Date since, Throwable t)
	{
		// as the external service is down, simply return "no updates"
		return new HashSet<>();
	}

	@CircuitBreaker(name="positionTracker", fallbackMethod="getHistoryForDown")
	public Collection<VehiclePosition> getHistoryFor(String vehicleName) {
		return remoteService.getHistoryFor(vehicleName);
	}
	
	public Collection<VehiclePosition> getHistoryForDown(String vehicleName, Throwable t) {
		return new HashSet<>();
	}
	
}
