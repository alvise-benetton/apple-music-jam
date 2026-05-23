/* ═══════════════════════════════════════════════════════════════════════════
   Apple Music JAM — Client Application (MQTT Serverless Edition)
   ═══════════════════════════════════════════════════════════════════════════ */

(function () {
    'use strict';

    /* ────────────────────────── UTILITIES ────────────────────────── */

    const Utils = {
        formatDuration(ms) {
            if (!ms || ms < 0) return '0:00';
            const totalSeconds = Math.floor(ms / 1000);
            const minutes = Math.floor(totalSeconds / 60);
            const seconds = totalSeconds % 60;
            return `${minutes}:${seconds.toString().padStart(2, '0')}`;
        },

        debounce(fn, delay) {
            let timerId = null;
            return function (...args) {
                clearTimeout(timerId);
                timerId = setTimeout(() => fn.apply(this, args), delay);
            };
        },

        escapeHtml(str) {
            if (!str) return '';
            const div = document.createElement('div');
            div.appendChild(document.createTextNode(str));
            return div.innerHTML;
        },

        generateId() {
            return Math.random().toString(36).substring(2, 10);
        },

        getBrowserName() {
            const ua = navigator.userAgent;
            if (ua.includes('Firefox')) return 'Firefox';
            if (ua.includes('Edg/')) return 'Edge';
            if (ua.includes('Chrome')) return 'Chrome';
            if (ua.includes('Safari')) return 'Safari';
            return ua.substring(0, 30);
        },

        getSessionId() {
            const params = new URLSearchParams(window.location.search);
            return params.get('session');
        }
    };

    /* ────────────────────────── STATE ────────────────────────── */

    const State = {
        sessionId: Utils.getSessionId(),
        clientId: 'JAM-Client-' + Utils.generateId(),
        clientName: Utils.getBrowserName(),
        mqttClient: null,

        songs: [],
        queue: [],
        nowPlaying: null,
        isPlaying: false,
        isConnected: false,
        activeTab: 'nowPlaying',
        elapsedTime: 0,
        _heartbeatIntervalId: null,

        update(updates) {
            Object.assign(this, updates);

            if ('isConnected' in updates) {
                UI.updateConnectionStatus(this.isConnected);
            }
            if ('songs' in updates) {
                UI.renderSearchResults(this.songs);
            }
            if ('nowPlaying' in updates || 'isPlaying' in updates || 'elapsedTime' in updates) {
                UI.renderNowPlaying(this);
            }
            if ('queue' in updates) {
                UI.renderQueue(this.queue);
            }
            if ('activeTab' in updates) {
                UI.switchTab(this.activeTab);
            }
        }
    };

    /* ────────────────────────── MQTT & JSONP ────────────────────────── */

    const Network = {
        initMQTT() {
            if (!State.sessionId) {
                UI.showToast('No session ID found in URL.', 'error');
                return;
            }

            const brokerUrl = 'wss://broker.hivemq.com:8884/mqtt';
            console.log(`Connecting to MQTT Broker: ${brokerUrl}`);

            State.mqttClient = mqtt.connect(brokerUrl, {
                clientId: State.clientId,
                clean: true,
                connectTimeout: 4000,
                reconnectPeriod: 2000
            });

            State.mqttClient.on('connect', () => {
                console.log('MQTT Connected');
                State.update({ isConnected: true });

                const stateTopic = `apple-music-jam/session/${State.sessionId}/state`;
                State.mqttClient.subscribe(stateTopic, { qos: 1 });

                this.sendHeartbeat();
            });

            State.mqttClient.on('message', (topic, message) => {
                try {
                    const data = JSON.parse(message.toString());
                    console.log('Received State Update:', data);
                    
                    State.update({
                        nowPlaying: data.currentSong || null,
                        isPlaying: data.isPlaying || false,
                        queue: data.queue || [],
                        elapsedTime: data.elapsedTime || 0
                    });
                } catch (e) {
                    console.error('Failed to parse MQTT message', e);
                }
            });

            State.mqttClient.on('error', (err) => {
                console.error('MQTT Error:', err);
                State.update({ isConnected: false });
            });

            State.mqttClient.on('close', () => {
                State.update({ isConnected: false });
            });
        },

        sendControl(action, payload = {}) {
            if (!State.mqttClient || !State.isConnected) return;

            const controlTopic = `apple-music-jam/session/${State.sessionId}/control`;
            const message = JSON.stringify({
                action: action,
                clientId: State.clientId,
                name: State.clientName,
                ...payload
            });

            State.mqttClient.publish(controlTopic, message, { qos: 1 });
        },

        sendHeartbeat() {
            this.sendControl('heartbeat');
        },

        searchiTunes(query) {
            return new Promise((resolve, reject) => {
                const callbackName = 'jsonp_callback_' + Math.round(100000 * Math.random());
                const script = document.createElement('script');
                
                window[callbackName] = function(data) {
                    delete window[callbackName];
                    document.body.removeChild(script);
                    resolve(data.results);
                };
                
                script.onerror = function() {
                    delete window[callbackName];
                    document.body.removeChild(script);
                    reject(new Error('JSONP request failed'));
                };
                
                script.src = `https://itunes.apple.com/search?term=${encodeURIComponent(query)}&entity=song&limit=25&country=IT&callback=${callbackName}`;
                document.body.appendChild(script);
            });
        }
    };

    /* ────────────────────────── DOM REFERENCES ────────────────────────── */

    const $ = (id) => document.getElementById(id);

    const DOM = {
        // Header
        statusDot: $('statusDot'),
        statusLabel: $('statusLabel'),
        connectionStatus: $('connectionStatus'),

        // Search
        searchInput: $('searchInput'),
        searchClear: $('searchClear'),
        searchLoader: $('searchLoader'),
        searchResultsSection: $('searchResultsSection'),
        searchResultsTitle: $('searchResultsTitle'),
        searchResults: $('searchResults'),

        // Tabs
        tabNowPlaying: $('tabNowPlaying'),
        tabQueue: $('tabQueue'),
        tabIndicator: $('tabIndicator'),
        queueBadge: $('queueBadge'),

        // Now Playing
        nowPlayingSection: $('nowPlayingSection'),
        npEmpty: $('npEmpty'),
        npActive: $('npActive'),
        npArtwork: $('npArtwork'),
        npTitle: $('npTitle'),
        npArtist: $('npArtist'),
        npEqualizer: $('npEqualizer'),
        progressFill: $('progressFill'),
        timeElapsed: $('timeElapsed'),
        timeTotal: $('timeTotal'),

        // Controls
        btnPrevious: $('btnPrevious'),
        btnPlayPause: $('btnPlayPause'),
        btnNext: $('btnNext'),
        iconPlay: $('iconPlay'),
        iconPause: $('iconPause'),

        // Queue
        queueSection: $('queueSection'),
        queueList: $('queueList'),
        queueCount: $('queueCount'),
        queueEmpty: $('queueEmpty'),

        // Toast
        toastContainer: $('toastContainer')
    };

    /* ────────────────────────── UI MODULE ────────────────────────── */

    const UI = {
        updateConnectionStatus(connected) {
            DOM.statusDot.classList.toggle('connected', connected);
            DOM.statusLabel.textContent = connected ? 'Live' : 'Offline';
            DOM.connectionStatus.title = connected ? 'Connected to server' : 'Disconnected';
        },

        setSearchLoading(loading) {
            DOM.searchLoader.hidden = !loading;
            DOM.searchClear.hidden = loading || !DOM.searchInput.value.trim();
        },

        showShimmer(count = 4) {
            DOM.searchResultsSection.hidden = false;
            DOM.searchResultsTitle.textContent = 'Searching...';
            let html = '';
            for (let i = 0; i < count; i++) {
                html += `
                    <div class="song-card song-card--shimmer" role="listitem" style="animation-delay:${i * 80}ms">
                        <div class="shimmer-block shimmer-artwork"></div>
                        <div class="song-info" style="gap:8px">
                            <div class="shimmer-block shimmer-text shimmer-text--title"></div>
                            <div class="shimmer-block shimmer-text shimmer-text--artist"></div>
                            <div class="shimmer-block shimmer-text shimmer-text--album"></div>
                        </div>
                    </div>`;
            }
            DOM.searchResults.innerHTML = html;
        },

        renderSearchResults(songs) {
            if (!songs || songs.length === 0) {
                if (DOM.searchInput.value.trim().length >= 2) {
                    DOM.searchResultsSection.hidden = false;
                    DOM.searchResultsTitle.textContent = 'No results found';
                    DOM.searchResults.innerHTML = `
                        <div class="np-empty" style="padding:var(--space-xl) 0">
                            <p class="np-empty-title" style="font-size:var(--font-size-base)">No songs found</p>
                            <p class="np-empty-subtitle">Try a different search term</p>
                        </div>`;
                } else {
                    DOM.searchResultsSection.hidden = true;
                    DOM.searchResults.innerHTML = '';
                }
                return;
            }

            DOM.searchResultsSection.hidden = false;
            DOM.searchResultsTitle.textContent = `${songs.length} result${songs.length !== 1 ? 's' : ''}`;

            const fragment = document.createDocumentFragment();
            songs.forEach((song, index) => {
                const card = document.createElement('div');
                card.className = 'song-card';
                card.setAttribute('role', 'listitem');
                card.style.animationDelay = `${index * 50}ms`;

                const artworkUrl = (song.artworkUrl100 || '').replace('100x100', '600x600');
                const title = Utils.escapeHtml(song.trackName || 'Unknown');
                const artist = Utils.escapeHtml(song.artistName || 'Unknown Artist');
                const album = Utils.escapeHtml(song.collectionName || '');
                const duration = song.trackTimeMillis || 0;

                card.innerHTML = `
                    <img class="song-artwork"
                         src="${Utils.escapeHtml(artworkUrl)}"
                         alt="${title} artwork"
                         loading="lazy"
                         onerror="this.src='data:image/svg+xml,<svg xmlns=\\'http://www.w3.org/2000/svg\\' viewBox=\\'0 0 60 60\\'><rect fill=\\' %23 1a1a2e\\' width=\\'60\\' height=\\'60\\'/><text x=\\'50%25\\' y=\\'50%25\\' text-anchor=\\'middle\\' dy=\\'.35em\\' font-size=\\'24\\'>🎵</text></svg>'">
                    <div class="song-info">
                        <span class="song-title">${title}</span>
                        <span class="song-artist">${artist}</span>
                        <div class="song-meta">
                            ${album ? `<span class="song-album">${album}</span><span class="dot-sep">•</span>` : ''}
                            <span class="song-duration">${Utils.formatDuration(duration)}</span>
                        </div>
                    </div>
                    <div class="song-actions">
                        <button class="btn btn--accent btn-play-now" aria-label="Play ${title} now" title="Play Now">▶ Play</button>
                        <button class="btn btn--secondary btn-add-queue" aria-label="Add ${title} to queue" title="Add to Queue">+ Queue</button>
                    </div>`;

                const btnPlay = card.querySelector('.btn-play-now');
                const btnQueue = card.querySelector('.btn-add-queue');

                btnPlay.addEventListener('click', (e) => {
                    e.stopPropagation();
                    Actions.playSong(song);
                });

                btnQueue.addEventListener('click', (e) => {
                    e.stopPropagation();
                    Actions.addToQueue(song);
                });

                fragment.appendChild(card);
            });

            DOM.searchResults.innerHTML = '';
            DOM.searchResults.appendChild(fragment);
        },

        renderNowPlaying(state) {
            const song = state.nowPlaying;

            if (!song) {
                DOM.npEmpty.hidden = false;
                DOM.npActive.hidden = true;
                return;
            }

            DOM.npEmpty.hidden = true;
            DOM.npActive.hidden = false;

            const artworkUrl = song.artworkUrl100 ? song.artworkUrl100.replace('100x100', '600x600') : '';
            const title = song.trackName || 'Unknown';
            const artist = song.artistName || 'Unknown Artist';
            const duration = song.trackTimeMillis || 0;

            const currentSrc = DOM.npArtwork.getAttribute('data-src');
            if (currentSrc !== artworkUrl) {
                DOM.npArtwork.src = artworkUrl || 'data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 300 300"><rect fill="%231a1a2e" width="300" height="300"/><text x="50%" y="50%" text-anchor="middle" dy=".35em" font-size="64">🎵</text></svg>';
                DOM.npArtwork.setAttribute('data-src', artworkUrl);
                DOM.npArtwork.alt = `${title} album artwork`;
            }

            DOM.npTitle.textContent = title;
            DOM.npArtist.textContent = artist;

            DOM.npEqualizer.hidden = false;
            DOM.npEqualizer.classList.toggle('paused', !state.isPlaying);

            const elapsed = state.elapsedTime || 0;
            if (duration > 0) {
                const percent = Math.min((elapsed / duration) * 100, 100);
                DOM.progressFill.style.width = `${percent}%`;
            } else {
                DOM.progressFill.style.width = '0%';
            }
            DOM.timeElapsed.textContent = Utils.formatDuration(elapsed * 1000); // MQTT sends seconds, we format ms
            DOM.timeTotal.textContent = Utils.formatDuration(duration);

            DOM.iconPlay.hidden = state.isPlaying;
            DOM.iconPause.hidden = !state.isPlaying;
            DOM.btnPlayPause.setAttribute('aria-label', state.isPlaying ? 'Pause' : 'Play');
            DOM.btnPlayPause.title = state.isPlaying ? 'Pause' : 'Play';
        },

        renderQueue(queue) {
            if (queue && queue.length > 0) {
                DOM.queueBadge.hidden = false;
                DOM.queueBadge.textContent = queue.length;
                DOM.queueCount.textContent = `${queue.length} song${queue.length !== 1 ? 's' : ''}`;
                DOM.queueEmpty.classList.remove('visible');
            } else {
                DOM.queueBadge.hidden = true;
                DOM.queueCount.textContent = '0 songs';
                DOM.queueEmpty.classList.add('visible');
            }

            if (!queue || queue.length === 0) {
                DOM.queueList.innerHTML = '';
                return;
            }

            const fragment = document.createDocumentFragment();
            queue.forEach((song, index) => {
                const item = document.createElement('div');
                item.className = 'queue-item';
                item.setAttribute('role', 'listitem');
                item.style.animationDelay = `${index * 40}ms`;

                const artworkUrl = song.artworkUrl100 ? song.artworkUrl100.replace('100x100', '600x600') : '';
                const title = Utils.escapeHtml(song.trackName || 'Unknown');
                const artist = Utils.escapeHtml(song.artistName || 'Unknown Artist');
                const duration = song.trackTimeMillis || 0;

                item.innerHTML = `
                    <span class="queue-pos">${index + 1}</span>
                    <img class="queue-artwork"
                         src="${Utils.escapeHtml(artworkUrl)}"
                         alt="${title}"
                         loading="lazy"
                         onerror="this.src='data:image/svg+xml,<svg xmlns=\\'http://www.w3.org/2000/svg\\' viewBox=\\'0 0 44 44\\'><rect fill=\\' %23 1a1a2e\\' width=\\'44\\' height=\\'44\\'/><text x=\\'50%25\\' y=\\'50%25\\' text-anchor=\\'middle\\' dy=\\'.35em\\' font-size=\\'16\\'>🎵</text></svg>'">
                    <div class="queue-info">
                        <span class="queue-title">${title}</span>
                        <span class="queue-artist">${artist}</span>
                    </div>
                    <span class="queue-duration">${Utils.formatDuration(duration)}</span>`;

                fragment.appendChild(item);
            });

            DOM.queueList.innerHTML = '';
            DOM.queueList.appendChild(fragment);
        },

        switchTab(tab) {
            const isQueue = tab === 'queue';

            DOM.tabNowPlaying.classList.toggle('active', !isQueue);
            DOM.tabQueue.classList.toggle('active', isQueue);
            DOM.tabNowPlaying.setAttribute('aria-selected', String(!isQueue));
            DOM.tabQueue.setAttribute('aria-selected', String(isQueue));
            DOM.tabIndicator.setAttribute('data-active', isQueue ? 'queue' : 'nowPlaying');

            DOM.nowPlayingSection.hidden = isQueue;
            DOM.queueSection.hidden = !isQueue;
        },

        showToast(message, type = 'info') {
            const icons = { success: '✅', error: '❌', info: 'ℹ️' };
            const toast = document.createElement('div');
            toast.className = `toast toast--${type}`;
            toast.innerHTML = `
                <span class="toast-icon">${icons[type] || icons.info}</span>
                <span>${Utils.escapeHtml(message)}</span>`;
            DOM.toastContainer.appendChild(toast);

            const dismissTimer = setTimeout(() => {
                toast.classList.add('dismissing');
                toast.addEventListener('animationend', () => toast.remove(), { once: true });
            }, 3000);

            toast.addEventListener('click', () => {
                clearTimeout(dismissTimer);
                toast.classList.add('dismissing');
                toast.addEventListener('animationend', () => toast.remove(), { once: true });
            });
        }
    };

    /* ────────────────────────── ACTIONS ────────────────────────── */

    const Actions = {
        async search(query) {
            const trimmed = query.trim();
            if (trimmed.length < 2) {
                State.update({ songs: [] });
                DOM.searchResultsSection.hidden = true;
                DOM.searchClear.hidden = !trimmed.length;
                return;
            }

            DOM.searchClear.hidden = true;
            UI.setSearchLoading(true);
            UI.showShimmer(4);

            try {
                const results = await Network.searchiTunes(trimmed);
                State.update({ songs: results });
            } catch (err) {
                console.error('Search failed:', err);
                UI.showToast('Search failed. Please try again.', 'error');
                State.update({ songs: [] });
            } finally {
                UI.setSearchLoading(false);
                DOM.searchClear.hidden = !DOM.searchInput.value.trim();
            }
        },

        playSong(song) {
            Network.sendControl('play', { song });
            UI.showToast(`Requested playback for ${song.trackName}`, 'info');
        },

        addToQueue(song) {
            Network.sendControl('queue_add', { song });
            UI.showToast(`Requested add to queue for ${song.trackName}`, 'info');
        },

        controlPlayback(action) {
            Network.sendControl('control', { command: action });
        }
    };

    /* ────────────────────────── INITIALIZATION ────────────────────────── */

    function init() {
        if (!State.sessionId) {
            UI.showToast('Missing session ID. Please scan the QR code from the server app.', 'error');
            return;
        }

        const debouncedSearch = Utils.debounce((e) => {
            Actions.search(e.target.value);
        }, 300);

        DOM.searchInput.addEventListener('input', debouncedSearch);

        DOM.searchInput.addEventListener('input', () => {
            const hasValue = DOM.searchInput.value.trim().length > 0;
            DOM.searchClear.hidden = !hasValue;
        });

        DOM.searchClear.addEventListener('click', () => {
            DOM.searchInput.value = '';
            DOM.searchClear.hidden = true;
            DOM.searchResultsSection.hidden = true;
            DOM.searchResults.innerHTML = '';
            State.update({ songs: [] });
            DOM.searchInput.focus();
        });

        DOM.btnPlayPause.addEventListener('click', () => {
            const action = State.isPlaying ? 'pause' : 'play';
            Actions.controlPlayback(action);
        });

        DOM.btnPrevious.addEventListener('click', () => {
            Actions.controlPlayback('previous');
        });

        DOM.btnNext.addEventListener('click', () => {
            Actions.controlPlayback('next');
        });

        DOM.tabNowPlaying.addEventListener('click', () => {
            State.update({ activeTab: 'nowPlaying' });
        });

        DOM.tabQueue.addEventListener('click', () => {
            State.update({ activeTab: 'queue' });
        });

        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape' && document.activeElement === DOM.searchInput) {
                DOM.searchInput.value = '';
                DOM.searchClear.hidden = true;
                DOM.searchResultsSection.hidden = true;
                DOM.searchResults.innerHTML = '';
                State.update({ songs: [] });
                DOM.searchInput.blur();
            }
        });

        UI.switchTab(State.activeTab);
        
        Network.initMQTT();

        State._heartbeatIntervalId = setInterval(() => {
            Network.sendHeartbeat();
        }, 15000);
    }

    document.addEventListener('DOMContentLoaded', init);

})();
