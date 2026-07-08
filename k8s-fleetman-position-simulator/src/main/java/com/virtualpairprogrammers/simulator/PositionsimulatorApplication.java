package com.virtualpairprogrammers.simulator;

import java.io.IOException;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.ConfigurableApplicationContext;

import com.virtualpairprogrammers.simulator.journey.JourneySimulator;

/**
 * A toy application which simulates the progress of vehicles on a delivery route.
 * The program reads from one or more text files containing a list of lat/long
 * positions (these can be created from .gpx files or similar).
 *
 * Messages are then sent on to a queue (currently hardcoded as positionQueue).
 */
@SpringBootApplication
public class PositionsimulatorApplication {

	public static void main(String[] args) throws IOException, InterruptedException 
	{
		try(ConfigurableApplicationContext ctx = SpringApplication.run(PositionsimulatorApplication.class))
		{
			final JourneySimulator simulator = ctx.getBean(JourneySimulator.class);

			Thread mainThread = new Thread(simulator);
			mainThread.start();
		}
		
	}

}

