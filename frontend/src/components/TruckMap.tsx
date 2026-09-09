'use client';
import { MapContainer, TileLayer, Marker, Popup, useMapEvents } from 'react-leaflet';
import 'leaflet/dist/leaflet.css';
import L from 'leaflet';
import { useEffect, useState, useCallback } from 'react';

const iconFix = () => {
  const iconDefault = L.Icon.Default as unknown as { _getIconUrl?: () => string };
  delete iconDefault._getIconUrl;
  L.Icon.Default.mergeOptions({
    iconRetinaUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon-2x.png',
    iconUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon.png',
    shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-shadow.png',
  });
};

const truckIcon = new L.Icon({
  iconUrl: 'https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-blue.png',
  shadowUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png',
  iconSize: [25, 41],
  iconAnchor: [12, 41],
  popupAnchor: [1, -34],
  shadowSize: [41, 41],
});

export interface TruckLocation {
  id: number;
  plate_number: string | null;
  vehicle_class: string;
  capacity: string;
  lat: number;
  lng: number;
}

interface TruckMapProps {
  trucks: TruckLocation[];
  center?: { lat: number; lng: number };
  zoom?: number;
  onTruckClick?: (truck: TruckLocation) => void;
}

export default function TruckMap({ trucks, center, zoom = 11, onTruckClick }: TruckMapProps) {
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    iconFix();
    const timer = setTimeout(() => setMounted(true), 0);
    return () => clearTimeout(timer);
  }, []);

  if (!mounted) {
    return <div className="h-96 w-full bg-gray-100 rounded-2xl animate-pulse" />;
  }

  const c = center ?? { lat: 30.0444, lng: 31.2357 };

  return (
    <div className="h-96 w-full rounded-2xl overflow-hidden shadow-inner">
      <MapContainer
        center={[c.lat, c.lng] as [number, number]}
        zoom={zoom}
        style={{ height: '100%', width: '100%' }}
        scrollWheelZoom={true}
      >
        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        />
        {trucks.map((truck) => (
          <Marker
            key={truck.id}
            position={[truck.lat, truck.lng] as [number, number]}
            icon={truckIcon}
            eventHandlers={{
              click: () => onTruckClick?.(truck),
            }}
          >
            <Popup>
              <div>
                <strong>{truck.vehicle_class}</strong>
                <br />
                Plate: {truck.plate_number || 'N/A'}
                <br />
                Capacity: {truck.capacity}
              </div>
            </Popup>
          </Marker>
        ))}
      </MapContainer>
    </div>
  );
}

export function TruckMapWithUser() {
  const [userPos, setUserPos] = useState<{ lat: number; lng: number } | null>(null);
  const [trucks, setTrucks] = useState<TruckLocation[]>([]);
  const [loading, setLoading] = useState(true);

  const loadTrucks = useCallback(async () => {
    try {
      const res = await fetch('/api/v1/trucks');
      const data = await res.json();
      // Assign near-Cairo coordinates until Truck model stores lat/lng
      const withCoords = (data || []).map((t: any, i: number) => ({
        ...t,
        lat: 30.0444 + (Math.random() - 0.5) * 0.15,
        lng: 31.2357 + (Math.random() - 0.5) * 0.15,
      }));
      setTrucks(withCoords);
    } catch {
      setTrucks([]);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadTrucks();
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        (pos) => setUserPos({ lat: pos.coords.latitude, lng: pos.coords.longitude }),
        () => setUserPos(null),
        { enableHighAccuracy: true, timeout: 8000, maximumAge: 30000 },
      );
    }
  }, [loadTrucks]);

  if (loading) {
    return <div className="h-96 w-full bg-gray-100 rounded-2xl animate-pulse" />;
  }

  return (
    <TruckMap
      trucks={trucks}
      center={userPos ?? { lat: 30.0444, lng: 31.2357 }}
      zoom={userPos ? 13 : 11}
    />
  );
}