'use client';
import { useEffect, useState } from 'react';
import { useAuth } from '@/contexts/AuthContext';
import { useRouter } from 'next/navigation';
import RoleGuard from '@/components/RoleGuard';
import TruckMapWithUser from '@/components/TruckMap';
import { VehicleType } from '@/lib/types';
import { getVehicleTypes, createJob } from '@/lib/api';

type CargoCategory = 'devices' | 'beds' | 'furniture' | 'general';

const truckSizes = [
  { code: 'small', label: 'Small', labelAr: 'صغير', hint: 'Up to 500 kg', hintAr: 'حتى 500 كجم', img: '/truck-pic/rb3-nq1.jpg' },
  { code: 'medium', label: 'Medium', labelAr: 'متوسط', hint: 'Up to 1.5 t', hintAr: 'حتى 1.5 طن', img: '/truck-pic/3byh-nq2.jpg' },
  { code: 'large', label: 'Large', labelAr: 'كبير', hint: 'Up to 5 t', hintAr: 'حتى 5 طن', img: '/truck-pic/ns-nq.jpg' },
  { code: 'xl', label: 'X-Large', labelAr: 'كبير جدا', hint: 'Up to 10 t', hintAr: 'حتى 10 طن', img: '/truck-pic/nq3th.webp' },
];

const categorySuggestions: Record<CargoCategory, string> = {
  devices: 'small',
  beds: 'large',
  furniture: 'xl',
  general: 'medium',
};

function BookPageContent() {
  const [view, setView] = useState<'intro' | 'category' | 'form'>('intro');
  const [category, setCategory] = useState<CargoCategory | null>(null);
  const [step, setStep] = useState(1);
  const [vehicles, setVehicles] = useState<VehicleType[]>([]);
  const [selectedVehicle, setSelectedVehicle] = useState<VehicleType | null>(null);
  const [pickup, setPickup] = useState('');
  const [dropoff, setDropoff] = useState('');
  const [budgetMin, setBudgetMin] = useState('');
  const [budgetMax, setBudgetMax] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const { token } = useAuth();
  const router = useRouter();

  useEffect(() => {
    getVehicleTypes()
      .then((loadedVehicles) => {
        setVehicles(loadedVehicles);
        if (category) {
          const suggested = loadedVehicles.find(
            (v) => v.code === categorySuggestions[category],
          );
          if (suggested) setSelectedVehicle(suggested);
        }
      })
      .catch(() => setError('Failed to load vehicles'));
  }, []);

  const handleCategorySelect = (cat: CargoCategory) => {
    setCategory(cat);
    const suggestedCode = categorySuggestions[cat];
    const suggested = vehicles.find((v) => v.code === suggestedCode);
    if (suggested) {
      setSelectedVehicle(suggested);
    } else {
      const fallback = vehicles[0];
      if (fallback) setSelectedVehicle(fallback);
    }
    setView('form');
    setStep(1);
  };

  const handleSubmit = async () => {
    if (!token || !selectedVehicle) return;

    setLoading(true);
    setError('');

    try {
      const idempotencyKey = `${Date.now()}-${Math.random().toString(36).slice(2, 9)}`;
      await createJob(token, {
        vehicle_class: selectedVehicle.code,
        pickup: {
          place_id: `map-pickup-${idempotencyKey}`,
          address: pickup,
          lat: 30.0 + Math.random() * 0.1,
          lng: 31.2 + Math.random() * 0.1,
        },
        dropoff: {
          place_id: `map-dropoff-${idempotencyKey}`,
          address: dropoff,
          lat: 30.0 + Math.random() * 0.1,
          lng: 31.2 + Math.random() * 0.1,
        },
        requested_min_price: parseFloat(budgetMin),
        requested_max_price: parseFloat(budgetMax),
        idempotency_key: idempotencyKey,
      });
      router.push('/trip');
    } catch (err) {
      const msg = err instanceof Error ? err.message : 'Failed to create job';
      if (msg.includes('verified') || msg.includes('phone')) {
        router.push('/profile');
      }
      setError(msg);
    } finally {
      setLoading(false);
    }
  };

  const handleNext = async () => {
    if (step === 4) {
      await handleSubmit();
      return;
    }
    setStep((s) => s + 1);
  };

  const canProceed = () => {
    switch (step) {
      case 1:
        return selectedVehicle !== null;
      case 2:
        return pickup.trim() !== '' && dropoff.trim() !== '';
      case 3:
        return budgetMin !== '' && budgetMax !== '' && parseFloat(budgetMin) <= parseFloat(budgetMax);
      default:
        return true;
    }
  };

  if (view === 'intro') {
    return (
      <div className="min-h-screen bg-white">
        <div className="p-4">
          <h2 className="text-xl font-bold mb-2 text-gray-900">Nearby Trucks</h2>
          <p className="text-sm text-gray-500 mb-4">Tap a truck to reserve it</p>
          <TruckMapWithUser />
        </div>
        <div className="p-4">
          <button
            onClick={() => setView('category')}
            className="w-full p-4 text-white rounded-xl font-bold transition-colors"
            style={{ background: '#e53935' }}
          >
            Book a Truck →
          </button>
        </div>
      </div>
    );
  }

  if (view === 'category') {
    return (
      <div className="min-h-screen bg-white py-8 px-4">
        <div className="max-w-md mx-auto">
          <h2 className="text-xl font-bold mb-6 text-center text-gray-900">What are you moving?</h2>
          <div className="space-y-3">
            <button
              onClick={() => handleCategorySelect('devices')}
              className="w-full p-4 border rounded-xl text-left hover:bg-gray-50 transition-colors"
              style={{ borderColor: '#e5e7eb' }}
            >
              <span className="text-xl mr-3">📱</span>
              <span className="font-medium text-gray-900">Devices & Electronics</span>
              <div className="text-sm text-gray-500 mt-1">Suggested: Small truck</div>
            </button>
            <button
              onClick={() => handleCategorySelect('beds')}
              className="w-full p-4 border rounded-xl text-left hover:bg-gray-50 transition-colors"
              style={{ borderColor: '#e5e7eb' }}
            >
              <span className="text-xl mr-3">🛏️</span>
              <span className="font-medium text-gray-900">Beds & Furniture</span>
              <div className="text-sm text-gray-500 mt-1">Suggested: Large truck</div>
            </button>
            <button
              onClick={() => handleCategorySelect('furniture')}
              className="w-full p-4 border rounded-xl text-left hover:bg-gray-50 transition-colors"
              style={{ borderColor: '#e5e7eb' }}
            >
              <span className="text-xl mr-3">📦</span>
              <span className="font-medium text-gray-900">Furniture</span>
              <div className="text-sm text-gray-500 mt-1">Suggested: X-Large truck</div>
            </button>
            <button
              onClick={() => handleCategorySelect('general')}
              className="w-full p-4 border rounded-xl text-left hover:bg-gray-50 transition-colors"
              style={{ borderColor: '#e5e7eb' }}
            >
              <span className="text-xl mr-3">📭</span>
              <span className="font-medium text-gray-900">Other / General</span>
              <div className="text-sm text-gray-500 mt-1">Suggested: Medium truck</div>
            </button>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-white py-8 px-4">
      <div className="max-w-2xl mx-auto bg-white rounded-2xl shadow-lg p-6" style={{ border: '1px solid #e5e7eb' }}>
        <h2 className="text-xl font-bold mb-4 text-gray-900">Request a Truck</h2>

        <div className="mb-6">
          <div className="flex justify-between mb-2">
            {['Vehicle', 'Locations', 'Budget', 'Confirm'].map((label, idx) => (
              <div
                key={label}
                className={`text-sm font-medium ${step === idx + 1 ? 'text-red-600' : 'text-gray-400'}`}
              >
                {label}
              </div>
            ))}
          </div>
          <div className="h-2 bg-gray-100 rounded-full">
            <div
              className="h-2 rounded-full transition-all duration-300"
              style={{ background: '#e53935', width: `${(step / 4) * 100}%` }}
            />
          </div>
        </div>

        {error && (
          <div className="mb-4 p-3 rounded-lg text-sm" style={{ background: '#ffebee', border: '1px solid #ffcdd2', color: '#b91c1c' }}>
            {error}
          </div>
        )}

        <div className="py-4">
          {step === 1 && (
            <div className="space-y-4">
              <p className="font-semibold mb-2 text-gray-800">Choose a vehicle</p>
              {category && (
                <p className="text-sm text-gray-600 mb-2">
                  Based on your category: <strong>{categorySuggestions[category]}</strong> truck is recommended
                </p>
              )}
              <div className="grid grid-cols-2 gap-3 mb-4">
                {truckSizes.map((ts) => (
                  <div
                    key={ts.code}
                    className="bg-white rounded-xl p-2 text-center border border-gray-200 shadow-sm"
                  >
                    <img src={ts.img} alt={ts.label} className="w-full h-20 object-cover rounded-lg mb-1" />
                    <p className="text-xs font-medium text-gray-700">{ts.label}</p>
                  </div>
                ))}
              </div>
              {vehicles.map((v) => (
                <div
                  key={v.id}
                  onClick={() => setSelectedVehicle(v)}
                  className={`p-4 border rounded-lg cursor-pointer transition-colors ${
                    selectedVehicle?.id === v.id ? 'border-red-500 bg-red-50' : 'border-gray-200 hover:border-gray-300'
                  }`}
                >
                  <div className="font-semibold text-gray-900">
                    {v.emoji} {v.label}
                  </div>
                  <div className="text-sm text-gray-500">{v.description}</div>
                  <div className="text-sm text-gray-400">
                    {v.capacity} · {v.priceRange} EGP
                  </div>
                </div>
              ))}
            </div>
          )}

          {step === 2 && (
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium mb-1 text-gray-700">Pickup Address</label>
                <input
                  type="text"
                  value={pickup}
                  onChange={(e) => setPickup(e.target.value)}
                  className="w-full p-3 border rounded-lg bg-white text-gray-900 placeholder-gray-400 focus:outline-none"
                  style={{ borderColor: '#e5e7eb' }}
                  placeholder="Enter pickup address"
                />
              </div>
              <div>
                <label className="block text-sm font-medium mb-1 text-gray-700">Dropoff Address</label>
                <input
                  type="text"
                  value={dropoff}
                  onChange={(e) => setDropoff(e.target.value)}
                  className="w-full p-3 border rounded-lg bg-white text-gray-900 placeholder-gray-400 focus:outline-none"
                  style={{ borderColor: '#e5e7eb' }}
                  placeholder="Enter dropoff address"
                />
              </div>
            </div>
          )}

          {step === 3 && (
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium mb-1 text-gray-700">Min Budget (EGP)</label>
                <input
                  type="number"
                  value={budgetMin}
                  onChange={(e) => setBudgetMin(e.target.value)}
                  className="w-full p-3 border rounded-lg bg-white text-gray-900 placeholder-gray-400 focus:outline-none"
                  style={{ borderColor: '#e5e7eb' }}
                />
              </div>
              <div>
                <label className="block text-sm font-medium mb-1 text-gray-700">Max Budget (EGP)</label>
                <input
                  type="number"
                  value={budgetMax}
                  onChange={(e) => setBudgetMax(e.target.value)}
                  className="w-full p-3 border rounded-lg bg-white text-gray-900 placeholder-gray-400 focus:outline-none"
                  style={{ borderColor: '#e5e7eb' }}
                />
              </div>
            </div>
          )}

          {step === 4 && (
            <div className="space-y-2 text-gray-800">
              <p><strong>Vehicle:</strong> {selectedVehicle?.label}</p>
              <p><strong>Pickup:</strong> {pickup}</p>
              <p><strong>Dropoff:</strong> {dropoff}</p>
              <p><strong>Budget:</strong> {budgetMin}–{budgetMax} EGP</p>
            </div>
          )}
        </div>

        <div className="flex gap-4">
          {step > 1 && (
            <button
              onClick={() => setStep((s) => s - 1)}
              className="flex-1 p-4 border rounded-xl font-bold hover:bg-gray-50 transition-colors"
              style={{ borderColor: '#e5e7eb', color: '#374151' }}
            >
              Back
            </button>
          )}
          <button
            onClick={handleNext}
            disabled={loading || !canProceed()}
            className="flex-1 p-4 text-white rounded-xl font-bold disabled:opacity-50 transition-colors"
            style={{ background: '#e53935' }}
          >
            {loading ? 'Processing...' : step === 4 ? 'Confirm Booking' : 'Next'}
          </button>
        </div>
      </div>
    </div>
  );
}

export default function BookPage() {
  return (
    <RoleGuard allowedRoles={['customer']}>
      <BookPageContent />
    </RoleGuard>
  );
}
