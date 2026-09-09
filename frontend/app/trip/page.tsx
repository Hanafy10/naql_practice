'use client';
import { useEffect, useState } from 'react';
import { useAuth } from '@/contexts/AuthContext';
import RoleGuard from '@/components/RoleGuard';
import { Job } from '@/lib/types';
import { getJobs, cancelJob } from '@/lib/api';

function TripPageContent() {
  const [jobs, setJobs] = useState<Job[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const { token } = useAuth();

  const loadJobs = async () => {
    if (!token) return;
    try {
      const data = await getJobs(token);
      setJobs(data);
    } catch {
      setError('Failed to load jobs');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadJobs();
  }, [token]);

  const handleCancel = async (jobId: number) => {
    if (!token || !confirm('Are you sure you want to cancel this request?')) return;
    try {
      await cancelJob(token, jobId);
      loadJobs();
    } catch {
      alert('Failed to cancel request');
    }
  };

  const statusColor = (status: string) => {
    switch (status) {
      case 'in_transit':
        return 'bg-emerald-100 text-emerald-800 border border-emerald-200';
      case 'awaiting_provider_price_approval':
      case 'awaiting_payment':
        return 'bg-amber-100 text-amber-800 border border-amber-200';
      case 'completed':
        return 'bg-gray-100 text-gray-700 border border-gray-200';
      case 'cancelled':
        return 'bg-red-100 text-red-700 border border-red-200';
      default:
        return 'bg-red-50 text-red-700 border border-red-200';
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-white">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-red-600" />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-white py-8 px-4">
      <div className="max-w-2xl mx-auto">
        <h1 className="text-2xl font-bold mb-6 text-gray-900">My Requests</h1>

        {error && (
          <div className="mb-4 p-3 rounded-lg text-sm" style={{ background: '#ffebee', border: '1px solid #ffcdd2', color: '#b91c1c' }}>
            {error}
          </div>
        )}

        {jobs.length === 0 ? (
          <div className="bg-white rounded-2xl shadow-sm p-12 text-center text-gray-500" style={{ border: '1px solid #e5e7eb' }}>
            <div className="text-4xl mb-4">📦</div>
            <p>No requests yet.</p>
          </div>
        ) : (
          <div className="space-y-4">
            {jobs.map((job) => (
              <div key={job.id} className="bg-white rounded-2xl shadow-sm p-6" style={{ border: '1px solid #e5e7eb' }}>
                <div className="flex justify-between items-start mb-4">
                  <div>
                    <h3 className="font-bold text-lg text-gray-900">Request #{job.id}</h3>
                    <p className="text-sm text-gray-500">
                      {job.truck_plate ? `${job.vehicle_class} · ${job.truck_plate}` : job.vehicle_class}
                    </p>
                  </div>
                  <span className={`px-3 py-1 rounded-full text-xs font-medium ${statusColor(job.status)}`}>
                    {job.status.replace(/_/g, ' ').toUpperCase()}
                  </span>
                </div>

                <div className="space-y-2 text-sm">
                  <div className="flex justify-between">
                    <span className="text-gray-500">Provider</span>
                    <span className="font-medium text-gray-700">{job.provider_name || `#${job.provider_id}`}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-500">Pickup</span>
                    <span className="font-medium text-gray-700">{job.pickup_address || 'Not set'}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-500">Dropoff</span>
                    <span className="font-medium text-gray-700">{job.dropoff_address || 'Not set'}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-500">Requested</span>
                    <span className="font-medium text-gray-700">
                      {job.requested_min_price?.toFixed(0)}–{job.requested_max_price?.toFixed(0)} EGP
                    </span>
                  </div>
                  {job.approved_price && (
                    <div className="flex justify-between">
                      <span className="text-gray-500">Approved</span>
                      <span className="font-medium text-red-600">{job.approved_price} EGP · payment pending</span>
                    </div>
                  )}
                </div>

                {(job.status === 'awaiting_provider_price_approval' || job.status === 'awaiting_payment') && (
                  <button
                    onClick={() => handleCancel(job.id)}
                    className="mt-4 px-4 py-2 border rounded-lg text-sm hover:bg-red-50 transition-colors"
                    style={{ borderColor: '#fecaca', color: '#b91c1c' }}
                  >
                    Cancel
                  </button>
                )}
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}

export default function TripPage() {
  return (
    <RoleGuard allowedRoles={['customer']}>
      <TripPageContent />
    </RoleGuard>
  );
}
