import { Component, OnInit } from '@angular/core';
import { LeafletModule } from '@asymmetrik/ngx-leaflet';
import { divIcon, latLng, Layer, Marker, marker, tileLayer, Map, point, polyline } from 'leaflet';

import { VehicleService } from '../vehicle.service';
import { Vehicle } from '../vehicle';

@Component({
  selector: 'app-map',
  templateUrl: './map.component.html',
  styleUrls: ['./map.component.css']
})
export class MapComponent implements OnInit {

  constructor(private vehicleService: VehicleService) { }

  markers: Marker[] = [];
  map: Map;
  centerVehicle: string;
  selectedVehicleHistory;

  options = {
    layers: [
       tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  { maxZoom: 18,
                    attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
                  })
    ],
    zoom: 16,
    center: latLng(53.375564, -1.506785)
  };

  onMapReady(map: Map) {
    this.map = map;
  }

  ngOnInit() {
    this.vehicleService.subscription.subscribe(vehicle => {
       if (vehicle == null) return;
       let foundIndex = this.markers.findIndex(existingMarker => existingMarker.options['title'] == vehicle.name);

       if (foundIndex == -1)
       {
         let newMarker = marker([vehicle.lat,vehicle.lng] ,
                                 {
                                   // Render a Font Awesome truck glyph as the marker (Font Awesome is
                                   // already loaded app-wide), instead of the default blue Leaflet pin.
                                   icon: divIcon( {
                                                    className: 'vehicle-marker',
                                                    html: '<i class="fa fa-truck"></i>',
                                                    iconSize: [ 30, 30 ],
                                                    iconAnchor: [ 15, 15 ]
                                                  }),
                                   title: vehicle.name
                                 }).bindTooltip(vehicle.name, {permanent:true, direction:'top', offset: point({x: 0, y: -12})});
         this.markers.push(newMarker);
       }
       else
       {
        this.markers[foundIndex].setLatLng(latLng(vehicle.lat, vehicle.lng));
       }
       if (this.centerVehicle == vehicle.name) {
         //this.map.setView([vehicle.lat,vehicle.lng],
        //                   this.map.getZoom(), {"animate": true});
         this.selectedVehicleHistory.addLatLng(latLng(vehicle.lat, vehicle.lng));
       }
     });

     this.vehicleService.centerVehicle.subscribe(vehicle => {
       if (vehicle == null)
       {
         this.centerVehicle = null;
         return;
       }
       this.centerVehicle = vehicle.name;
       this.map.flyTo([vehicle.lat,vehicle.lng],
                         this.map.getZoom(), {
       				   	       "animate": true
       				  });
     });

     this.vehicleService.centerVehicleHistory.subscribe(newHistory => {
       if (this.selectedVehicleHistory != null) this.selectedVehicleHistory.remove(this.map);
       if (newHistory ==null) return;
       this.selectedVehicleHistory = polyline(newHistory, {weight:10, opacity:0.5, color:'red'});
       this.selectedVehicleHistory.addTo(this.map);
     });
   }
}
