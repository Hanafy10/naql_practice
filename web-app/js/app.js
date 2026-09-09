  window.naqlApp = {
    state: {
      user: null,
      isLoading: false,
      currentScreen: 'auth',
      previousScreen: null,
      selectedVehicle: null,
      vehicleTypes: [],
      pickupLocation: null,
      dropoffLocation: null,
      scheduleMode: 'now',
      budgetMin: '',
      budgetMax: '',
      paymentMethod: 'cash',
      bookStep: 0,
      jobs: [],
      messages: [],
      adminTab: 0,
      adminStats: null,
      adminRequests: [],
      adminDrivers: [],
      providerFleet: [],
      providerTab: 0,
      authError: '',
      bookingError: '',
    },

    _escapeHtml(str) {
      if (typeof str !== 'string') return str;
      return str
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#039;');
    },

    async init() {
      if (!window.naqlApi && typeof ApiClient !== 'undefined') {
        try {
          window.naqlApi = new ApiClient();
        } catch (e) {
          console.error('Failed to instantiate fallback ApiClient:', e);
        }
      }

      window._selectedRegRole = 'customer';

      let token = null;
      let user = null;
      try {
        token = localStorage.getItem('naql_token');
        const rawUser = localStorage.getItem('naql_user');
        user = (rawUser && rawUser !== 'undefined') ? JSON.parse(rawUser) : null;
      } catch (err) {
        console.warn('Failed to parse localStorage token/user in app.init:', err);
      }

      if (token && user) {
        try {
          const api = this.getApi();
          api.setToken(token);
          api.setUser(user);
          const verifiedUser = await api.getCurrentUser();
          this.state.user = verifiedUser;
          this.state.currentScreen = 'app';
          this.showApp();
        } catch (e) {
          console.warn('Could not restore user session:', e);
          this.clearAuth();
          this.showAuth();
        }
      } else {
        this.showAuth();
      }

      window.addEventListener('popstate', () => this.handleRoute());
      this.handleRoute();
      await this.loadVehicleTypes();
    },

    handleRoute() {
      const hash = window.location.hash.slice(1) || '';
      if (hash.startsWith('screen/')) {
        const screen = hash.replace('screen/', '');
        if (['book', 'trip', 'chat', 'profile', 'provider'].includes(screen)) {
          if (!this.state.user) {
            window.location.hash = '';
            this.showAuth();
            return;
          }
          if (screen === 'provider' && this.state.user?.role !== 'provider') {
            window.location.hash = 'screen/book';
            this.navigateTo('book');
            return;
          }
          if (screen === 'book' && this.state.user?.role === 'provider') {
            window.location.hash = 'screen/provider';
            this.navigateTo('provider');
            return;
          }
          this.navigateTo(screen);
        }
      }
    },

    navigateTo(screen) {
      if (['book', 'trip', 'chat', 'profile', 'provider'].includes(screen) && !this.state.user) {
        this.showAuth();
        return;
      }
      if (screen === 'provider' && this.state.user?.role !== 'provider') {
        this.showAuth();
        return;
      }
      window.location.hash = `screen/${screen}`;
      this.state.previousScreen = this.state.currentScreen;
      this.state.currentScreen = screen;
      this.render();
    },

    showAuth() {
      this.state.currentScreen = 'auth';
      this.state.authError = '';
      this.render();
    },

    showApp() {
      this.state.currentScreen = 'app';
      this.state.authError = '';
      this.render();
    },

    clearAuth() {
      try {
        localStorage.removeItem('naql_token');
        localStorage.removeItem('naql_user');
      } catch (e) {
        console.warn('Failed to clear localStorage:', e);
      }
      try {
        if (window.naqlApi) {
          window.naqlApi.setToken(null);
          window.naqlApi.setUser(null);
        }
      } catch (e) {
        console.warn('Failed to clear API auth:', e);
      }
      this.state.user = null;
      this.state.currentScreen = 'auth';
      this.state.selectedVehicle = null;
      this.state.bookStep = 0;
      this.state.authError = '';
      this.state.bookingError = '';
    },

    getApi() {
      const Client = window.ApiClient || (typeof ApiClient !== 'undefined' ? ApiClient : null);
      if (!window.naqlApi && Client) {
        try {
          window.naqlApi = new Client();
        } catch (e) {
          console.error('Failed to initialize ApiClient:', e);
        }
      }
      if (!window.naqlApi) {
        throw new Error('API client is unavailable. Please check your browser storage settings and refresh.');
      }
      return window.naqlApi;
    },

    async login(identifier, password) {
      this.state.isLoading = true;
      this.state.authError = '';
      this.render();
      try {
        const api = this.getApi();
        const data = await api.login(identifier, password);
        api.setToken(data.access_token);
        const user = await api.getCurrentUser();
        api.setUser(user);
        this.state.user = user;
        this.state.currentScreen = 'app';
        this.render();
      } catch (err) {
        this.state.authError = err.message || 'Login failed';
        this.state.isLoading = false;
        this.render();
      }
    },

    async register(username, email, password, role) {
      this.state.isLoading = true;
      this.state.authError = '';
      this.render();
      try {
        const api = this.getApi();
        await api.register(username, email, password, role);
        await this.login(username, password);
      } catch (err) {
        this.state.authError = err.message || 'Registration failed';
        this.state.isLoading = false;
        this.render();
      }
    },

    logout() {
      this.clearAuth();
      this.render();
    },

    async loadVehicleTypes() {
      try {
        const types = await this.getApi().getVehicleTypes();
        this.state.vehicleTypes = types;
      } catch (err) {
        console.error('Failed to load vehicle types:', err);
      }
    },

    async loadAdminData() {
      try {
        const api = this.getApi();
        const [stats, requests, drivers] = await Promise.all([
          api.getAdminStats(),
          api.getAdminRequests(),
          api.getAdminDrivers(),
        ]);
        this.state.adminStats = stats;
        this.state.adminRequests = requests;
        this.state.adminDrivers = drivers;
      } catch (err) {
        console.error('Failed to load admin data:', err);
      }
    },

    async loadUserStats() {
      try {
        const stats = await this.getApi().getUserStats();
        this.state.userStats = stats;
        const container = document.getElementById('profile-stats');
        if (container) {
          container.innerHTML = `
            <div class="stat-item">
              <div class="stat-value">${stats.trips || 0}</div>
              <div class="stat-label">Trips</div>
            </div>
            <div class="stat-divider"></div>
            <div class="stat-item">
              <div class="stat-value">${stats.rating || '0.0'} ⭐</div>
              <div class="stat-label">Rating</div>
            </div>
            <div class="stat-divider"></div>
            <div class="stat-item">
              <div class="stat-value">${stats.savedEGP || 0} EGP</div>
              <div class="stat-label">Saved</div>
            </div>
          `;
        }
      } catch (err) {
        console.error('Failed to load user stats:', err);
      }
    },

    render() {
      const app = document.getElementById('app');
      if (!app) return;

      // Auth guard: never show app screens without a user
      if (!this.state.user && ['app', 'book', 'trip', 'chat', 'profile', 'provider'].includes(this.state.currentScreen)) {
        this.state.currentScreen = 'auth';
      }

      switch (this.state.currentScreen) {
        case 'auth':
          app.innerHTML = window.naqlScreens.renderAuth();
          break;
        case 'app':
          app.innerHTML = window.naqlScreens.renderAppShell();
          this.renderScreen();
          break;
        default:
          if (['book', 'trip', 'chat', 'profile', 'provider'].includes(this.state.currentScreen)) {
            if (!this.state.user) {
              this.state.currentScreen = 'auth';
              app.innerHTML = window.naqlScreens.renderAuth();
            } else {
              app.innerHTML = window.naqlScreens.renderAppShell();
              this.renderScreen();
            }
          }
      }
    },

    renderScreen() {
      const content = document.getElementById('screen-content');
      if (!content) return;

      let screen = this.state.currentScreen;
      if (screen === 'app') screen = this.state.user?.role === 'provider' ? 'provider' : 'book';

      switch (screen) {
        case 'book':
          if (this.state.user?.role === 'provider') {
            this.navigateTo('provider');
            return;
          }
          content.innerHTML = window.naqlScreens.renderBookFlow();
          break;
        case 'trip':
          content.innerHTML = window.naqlScreens.renderTripScreen();
          this.loadJobs();
          break;
        case 'chat':
          content.innerHTML = window.naqlScreens.renderChatScreen();
          break;
        case 'profile':
          content.innerHTML = window.naqlScreens.renderProfileScreen();
          this.loadUserStats();
          break;
        case 'provider':
          content.innerHTML = window.naqlScreens.renderProviderScreen();
          this.loadProviderFleet();
          this.loadJobs();
          break;
        default:
          if (this.state.user?.role === 'provider') {
            content.innerHTML = window.naqlScreens.renderProviderScreen();
            this.loadProviderFleet();
            this.loadJobs();
          } else {
            content.innerHTML = window.naqlScreens.renderBookFlow();
          }
      }
    },

    async loadJobs() {
      try {
        const api = this.getApi();
        let jobs;
        if (this.state.user?.role === 'provider') {
          jobs = await api.request('/provider/jobs');
        } else {
          jobs = await api.getJobs();
        }
        const mapped = (jobs || []).map(job => job instanceof JobData ? job : new JobData(job));
        this.state.jobs = mapped;
        const container = document.getElementById('jobs-list');
        if (container) {
          container.innerHTML = window.naqlScreens.renderJobsList(mapped);
        }
      } catch (err) {
        console.error('Failed to load jobs:', err);
      }
    },

    async submitBooking() {
      const { selectedVehicle, pickupLocation, dropoffLocation, budgetMin, budgetMax, paymentMethod } = this.state;
      const pickupAddress = pickupLocation?.address || document.getElementById('pickup-address')?.value;
      const dropoffAddress = dropoffLocation?.address || document.getElementById('dropoff-address')?.value;

      if (!selectedVehicle || !pickupAddress || !dropoffAddress) {
        this.state.bookingError = 'Please complete all required fields';
        this.render();
        return;
      }

      const min = parseFloat(budgetMin);
      const max = parseFloat(budgetMax);
      if (isNaN(min) || isNaN(max) || min > max) {
        this.state.bookingError = 'Please enter a valid price range';
        this.render();
        return;
      }

      // Confirmation step
      const confirmed = confirm(
        `Submit request?\n\n` +
        `Vehicle: ${selectedVehicle.label}\n` +
        `Pickup: ${pickupAddress}\n` +
        `Drop-off: ${dropoffAddress}\n` +
        `Budget: ${min}–${max} EGP\n` +
        `Payment: ${paymentMethod === 'cash' ? 'Cash' : 'Visa'}`
      );
      if (!confirmed) return;

      this.state.isLoading = true;
      this.state.bookingError = '';
      this.render();

      try {
        const id = Date.now().toString() + '-' + Math.random().toString(36).slice(2, 9);
        const place = (address, lat, lng) => ({
          place_id: `map-${id}-${Math.abs(address.split('').reduce((a, b) => ((a << 5) - a + b.charCodeAt(0)) | 0, 0))}`,
          address: address,
          lat: lat || 0.0,
          lng: lng || 0.0,
        });

        const payload = {
          vehicle_class: selectedVehicle.code,
          pickup: place(pickupAddress, pickupLocation?.lat, pickupLocation?.lng),
          dropoff: place(dropoffAddress, dropoffLocation?.lat, dropoffLocation?.lng),
          requested_min_price: min,
          requested_max_price: max,
          idempotency_key: id,
        };

        await this.getApi().createJob(payload);
        this.state.isLoading = false;
        this.state.bookStep = 0;
        this.state.selectedVehicle = null;
        this.state.pickupLocation = null;
        this.state.dropoffLocation = null;
        this.state.budgetMin = '';
        this.state.budgetMax = '';
        this.state.paymentMethod = 'cash';
        this.state.scheduleMode = 'now';
        this.navigateTo('trip');
      } catch (err) {
        this.state.bookingError = this._escapeHtml(err.message || 'Failed to submit request');
        this.state.isLoading = false;
        this.render();
      }
    },
    selectVehicle(vehicle) {
      this.state.selectedVehicle = vehicle;
      this.renderScreen();
    },

    setPickupLocation(lat, lng, address) {
      this.state.pickupLocation = { lat, lng, address };
      this.renderScreen();
    },

    setDropoffLocation(lat, lng, address) {
      this.state.dropoffLocation = { lat, lng, address };
      this.renderScreen();
    },

    setScheduleMode(mode) {
      this.state.scheduleMode = mode;
      this.renderScreen();
    },

    setBudget(min, max) {
      this.state.budgetMin = min;
      this.state.budgetMax = max;
    },

    setPaymentMethod(method) {
      this.state.paymentMethod = method;
      this.renderScreen();
    },

    setProviderTab(tab) {
      this.state.providerTab = tab;
      this.renderScreen();
    },

    async loadProviderFleet() {
      try {
        const fleet = await this.getApi().getProviderFleet();
        this.state.providerFleet = fleet;
        if (this.state.currentScreen === 'provider') {
          this.renderScreen();
        }
      } catch (err) {
        console.error('Failed to load provider fleet:', err);
      }
    },
  };
