'use client';
import { useEffect, useState } from 'react';
import { useAuth } from '@/contexts/AuthContext';
import RoleGuard from '@/components/RoleGuard';
import { getUserStats, updateUser } from '@/lib/api';

function ProfilePageContent() {
  const { user, token, logout, refreshUser } = useAuth();
  const [stats, setStats] = useState<{ trips: number; rating: number; savedEGP: number } | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [phoneInput, setPhoneInput] = useState('');
  const [message, setMessage] = useState('');

  useEffect(() => {
    if (!token) return;
    getUserStats(token)
      .then(setStats)
      .catch(() => setStats(null))
      .finally(() => setLoading(false));
  }, [token]);

  const handlePhoneSave = async () => {
    if (!token || !phoneInput.trim()) return;
    setSaving(true);
    setMessage('');
    try {
      await updateUser(token, { phone_number: phoneInput.trim() });
      await refreshUser();
      setMessage('Phone updated successfully');
      setPhoneInput('');
    } catch {
      setMessage('Failed to update phone');
    } finally {
      setSaving(false);
    }
  };

  const handleUpdate = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    if (!token) return;
    setSaving(true);
    setMessage('');
    const form = e.currentTarget;
    const username = (form.elements.namedItem('username') as HTMLInputElement).value;
    const email = (form.elements.namedItem('email') as HTMLInputElement).value;
    const password = (form.elements.namedItem('password') as HTMLInputElement).value;

    try {
      await updateUser(token, {
        ...(username ? { username } : {}),
        ...(email ? { email } : {}),
        ...(password ? { password } : {}),
      });
      await refreshUser();
      setMessage('Profile updated successfully');
    } catch {
      setMessage('Failed to update profile');
    } finally {
      setSaving(false);
    }
  };

  if (!user) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-white">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-red-600" />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-white py-8 px-4">
      <div className="max-w-2xl mx-auto space-y-6">
        <div className="bg-white rounded-2xl shadow-sm p-6" style={{ border: '1px solid #e5e7eb' }}>
          <div className="flex items-center gap-4 mb-6">
            <div className="w-16 h-16 rounded-full flex items-center justify-center text-2xl font-bold" style={{ background: '#ffebee', color: '#e53935', border: '2px solid #ffcdd2' }}>
              {(user.username || user.email || 'U').slice(0, 2).toUpperCase()}
            </div>
            <div>
              <h1 className="text-2xl font-bold text-gray-900">{user.username || 'User'}</h1>
              <p className="text-sm text-gray-500">{user.email}</p>
            </div>
          </div>

          <div className="mb-6 p-4 bg-gray-50 rounded-xl">
            <label className="block text-sm font-medium mb-1 text-gray-700">Phone Number</label>
            <div className="flex gap-2">
              <input
                type="tel"
                value={phoneInput || user.phone_number || ''}
                onChange={(e) => setPhoneInput(e.target.value)}
                className="flex-1 p-2 border rounded-lg bg-white text-gray-900"
                style={{ borderColor: '#e5e7eb' }}
                placeholder="Add your phone number"
              />
              <button
                onClick={handlePhoneSave}
                disabled={saving || !phoneInput.trim()}
                className="px-4 py-2 text-white rounded-lg font-medium disabled:opacity-50 transition-colors"
                style={{ background: '#e53935' }}
              >
                {saving ? 'Adding...' : 'Add'}
              </button>
            </div>
            <p className="text-xs text-gray-500 mt-1">
              Service: خدمه عملاد 01555444333
            </p>
          </div>

          {message && (
            <div className="mb-4 p-3 rounded-lg text-sm" style={{ background: message.includes('success') ? '#dcfce7' : '#ffebee', border: '1px solid', borderColor: message.includes('success') ? '#86efac' : '#ffcdd2', color: message.includes('success') ? '#166534' : '#b91c1c' }}>
              {message}
            </div>
          )}

          <form onSubmit={handleUpdate} className="space-y-4">
            <div>
              <label className="block text-sm font-medium mb-1 text-gray-700">Username</label>
              <input
                name="username"
                type="text"
                defaultValue={user.username || ''}
                className="w-full p-3 border rounded-lg bg-white text-gray-900 placeholder-gray-400 focus:outline-none"
                style={{ borderColor: '#e5e7eb' }}
              />
            </div>
            <div>
              <label className="block text-sm font-medium mb-1 text-gray-700">Email</label>
              <input
                name="email"
                type="email"
                defaultValue={user.email || ''}
                className="w-full p-3 border rounded-lg bg-white text-gray-900 placeholder-gray-400 focus:outline-none"
                style={{ borderColor: '#e5e7eb' }}
              />
            </div>
            <div>
              <label className="block text-sm font-medium mb-1 text-gray-700">New Password</label>
              <input
                name="password"
                type="password"
                placeholder="Leave blank to keep current"
                className="w-full p-3 border rounded-lg bg-white text-gray-900 placeholder-gray-400 focus:outline-none"
                style={{ borderColor: '#e5e7eb' }}
                minLength={12}
              />
            </div>
            <button
              type="submit"
              disabled={saving}
              className="w-full p-4 text-white rounded-xl font-bold disabled:opacity-50 transition-colors"
              style={{ background: '#e53935' }}
            >
              {saving ? 'Saving...' : 'Update Profile'}
            </button>
          </form>
        </div>

        <div className="bg-white rounded-2xl shadow-sm p-6" style={{ border: '1px solid #e5e7eb' }}>
          <h2 className="text-xl font-bold mb-4 text-gray-900">Stats</h2>
          {loading ? (
            <div className="animate-pulse space-y-2">
              <div className="h-4 bg-gray-100 rounded w-1/2" />
              <div className="h-4 bg-gray-100 rounded w-1/3" />
            </div>
          ) : stats ? (
            <div className="grid grid-cols-3 gap-4 text-center">
              <div>
                <div className="text-2xl font-bold text-gray-900">{stats.trips}</div>
                <div className="text-sm text-gray-500">Trips</div>
              </div>
              <div>
                <div className="text-2xl font-bold text-gray-900">{stats.rating} ⭐</div>
                <div className="text-sm text-gray-500">Rating</div>
              </div>
              <div>
                <div className="text-2xl font-bold text-gray-900">{stats.savedEGP}</div>
                <div className="text-sm text-gray-500">Saved EGP</div>
              </div>
            </div>
          ) : (
            <p className="text-gray-500">No stats available</p>
          )}
        </div>

        <button
          onClick={logout}
          className="w-full p-4 border rounded-xl font-bold hover:bg-red-50 transition-colors"
          style={{ borderColor: '#fecaca', color: '#b91c1c' }}
        >
          Sign Out
        </button>
      </div>
    </div>
  );
}

export default function ProfilePage() {
  return (
    <RoleGuard allowedRoles={['customer', 'provider']}>
      <ProfilePageContent />
    </RoleGuard>
  );
}
