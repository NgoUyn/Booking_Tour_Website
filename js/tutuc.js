// TuTuc - Places Discovery App
let map;
let service;
let markers = [];
let userLocation = null;
let currentPlaces = [];

// Initialize Map
function initMap() {
    // Default location (Ho Chi Minh City)
    const defaultLocation = { lat: 10.8231, lng: 106.6297 };
    
    map = new google.maps.Map(document.getElementById('map'), {
        center: defaultLocation,
        zoom: 15,
        mapTypeControl: false,
        streetViewControl: false,
        fullscreenControl: true
    });

    service = new google.maps.places.PlacesService(map);
    
    // Get user's location automatically
    getUserLocation();
    
    // Initialize event listeners
    initializeEventListeners();
}

// Get User Location
function getUserLocation() {
    if (navigator.geolocation) {
        navigator.geolocation.getCurrentPosition(
            (position) => {
                userLocation = {
                    lat: position.coords.latitude,
                    lng: position.coords.longitude
                };
                
                map.setCenter(userLocation);
                map.setZoom(15);
                
                // Add user location marker
                new google.maps.Marker({
                    position: userLocation,
                    map: map,
                    title: 'Vị trí của bạn',
                    icon: {
                        url: 'data:image/svg+xml;charset=UTF-8,' + encodeURIComponent(`
                            <svg width="20" height="20" xmlns="http://www.w3.org/2000/svg">
                                <circle cx="10" cy="10" r="8" fill="#4285f4" stroke="white" stroke-width="2"/>
                            </svg>
                        `),
                        scaledSize: new google.maps.Size(20, 20)
                    }
                });
                
                // Search for nearby places
                searchNearbyPlaces();
            },
            (error) => {
                console.error('Error getting location:', error);
                showLocationError();
                // Use default location and search
                searchNearbyPlaces(defaultLocation);
            },
            {
                enableHighAccuracy: true,
                timeout: 10000,
                maximumAge: 300000
            }
        );
    } else {
        showLocationError();
        searchNearbyPlaces();
    }
}

// Search Nearby Places
function searchNearbyPlaces(location = userLocation) {
    if (!location) {
        location = { lat: 10.8231, lng: 106.6297 }; // Default to Ho Chi Minh City
    }

    const request = {
        location: location,
        radius: 5000, // 5km radius
        type: ['tourist_attraction', 'restaurant', 'lodging', 'shopping_mall', 'park'],
        fields: ['place_id', 'name', 'rating', 'vicinity', 'types', 'geometry', 'photos', 'price_level']
    };

    service.nearbySearch(request, (results, status) => {
        if (status === google.maps.places.PlacesServiceStatus.OK) {
            // Sort by rating (highest first)
            results.sort((a, b) => (b.rating || 0) - (a.rating || 0));
            
            currentPlaces = results.slice(0, 20); // Limit to top 20 places
            displayPlaces(currentPlaces);
            addMarkersToMap(currentPlaces, location);
        } else {
            console.error('Places search failed:', status);
            showNoResultsMessage();
        }
    });
}

// Display Places in List
function displayPlaces(places) {
    const placesList = document.getElementById('placesList');
    
    if (places.length === 0) {
        placesList.innerHTML = '<div class="text-center py-4"><p>Không tìm thấy địa điểm nào.</p></div>';
        return;
    }
    
    placesList.innerHTML = places.map((place, index) => {
        const distance = userLocation ? calculateDistance(userLocation, place.geometry.location) : null;
        const photoUrl = place.photos && place.photos[0] ? 
            place.photos[0].getUrl({maxWidth: 100, maxHeight: 100}) : 
            'https://via.placeholder.com/100x100?text=No+Image';
            
        return `
            <div class="place-card" data-place-index="${index}" onclick="selectPlace(${index})">
                <div class="d-flex">
                    <img src="${photoUrl}" alt="${place.name}" class="me-3" style="width: 60px; height: 60px; object-fit: cover; border-radius: 8px;">
                    <div class="flex-grow-1">
                        <div class="place-name">${place.name}</div>
                        ${place.rating ? `
                            <div class="place-rating">
                                <span class="rating-stars">${'★'.repeat(Math.floor(place.rating))}${'☆'.repeat(5-Math.floor(place.rating))}</span>
                                <span class="rating-text">${place.rating.toFixed(1)} (${place.user_ratings_total || 0} đánh giá)</span>
                            </div>
                        ` : ''}
                        <div class="place-address">
                            <i class="fas fa-map-marker-alt"></i>
                            ${place.vicinity}
                        </div>
                        <div class="place-type">${getPlaceTypeInVietnamese(place.types[0])}</div>
                        ${distance ? `<div class="place-distance">📍 Cách ${distance.toFixed(1)} km</div>` : ''}
                    </div>
                </div>
            </div>
        `;
    }).join('');
}

// Add Markers to Map
function addMarkersToMap(places, userLocation) {
    // Clear existing markers
    markers.forEach(marker => marker.setMap(null));
    markers = [];
    
    places.forEach((place, index) => {
        const marker = new google.maps.Marker({
            position: place.geometry.location,
            map: map,
            title: place.name,
            animation: google.maps.Animation.DROP
        });
        
        // Create info window
        const infoWindow = new google.maps.InfoWindow({
            content: createInfoWindowContent(place, index)
        });
        
        marker.addListener('click', () => {
            // Close other info windows
            markers.forEach((m, i) => {
                if (m.infoWindow) m.infoWindow.close();
            });
            infoWindow.open(map, marker);
            selectPlace(index);
        });
        
        marker.infoWindow = infoWindow;
        markers.push(marker);
    });
}

// Create Info Window Content
function createInfoWindowContent(place, index) {
    const photoUrl = place.photos && place.photos[0] ? 
        place.photos[0].getUrl({maxWidth: 200, maxHeight: 150}) : '';
    
    return `
        <div class="info-window">
            ${photoUrl ? `<img src="${photoUrl}" alt="${place.name}" style="width: 100%; height: 100px; object-fit: cover; border-radius: 4px; margin-bottom: 8px;">` : ''}
            <h6>${place.name}</h6>
            ${place.rating ? `
                <div class="rating">
                    ${'★'.repeat(Math.floor(place.rating))}${'☆'.repeat(5-Math.floor(place.rating))} 
                    ${place.rating.toFixed(1)}
                </div>
            ` : ''}
            <div class="address">${place.vicinity}</div>
            <button class="btn btn-primary btn-sm" onclick="showPlaceDetails('${place.place_id}')">
                Xem chi tiết
            </button>
        </div>
    `;
}

// Select Place
function selectPlace(index) {
    // Remove previous selection
    document.querySelectorAll('.place-card').forEach(card => {
        card.classList.remove('selected');
    });
    
    // Add selection to current place
    const selectedCard = document.querySelector(`[data-place-index="${index}"]`);
    if (selectedCard) {
        selectedCard.classList.add('selected');
        selectedCard.scrollIntoView({ behavior: 'smooth', block: 'center' });
    }
    
    // Pan map to selected place
    const place = currentPlaces[index];
    if (place) {
        map.panTo(place.geometry.location);
        map.setZoom(16);
    }
}

// Initialize Event Listeners
function initializeEventListeners() {
    // Locate button
    document.getElementById('locateBtn').addEventListener('click', () => {
        getUserLocation();
    });
    
    // Category filter
    document.getElementById('categoryFilter').addEventListener('change', (e) => {
        filterPlacesByCategory(e.target.value);
    });
    
    // Search functionality
    document.getElementById('searchBtn').addEventListener('click', performSearch);
    document.getElementById('searchInput').addEventListener('keypress', (e) => {
        if (e.key === 'Enter') {
            performSearch();
        }
    });
}

// Filter Places by Category
function filterPlacesByCategory(category) {
    if (category === 'all') {
        displayPlaces(currentPlaces);
        addMarkersToMap(currentPlaces, userLocation);
        return;
    }
    
    const filteredPlaces = currentPlaces.filter(place => 
        place.types.includes(category)
    );
    
    displayPlaces(filteredPlaces);
    addMarkersToMap(filteredPlaces, userLocation);
}

// Perform Search
function performSearch() {
    const query = document.getElementById('searchInput').value.trim();
    if (!query) return;
    
    const request = {
        location: userLocation || { lat: 10.8231, lng: 106.6297 },
        radius: 10000,
        query: query,
        fields: ['place_id', 'name', 'rating', 'vicinity', 'types', 'geometry', 'photos']
    };
    
    service.textSearch(request, (results, status) => {
        if (status === google.maps.places.PlacesServiceStatus.OK) {
            currentPlaces = results.slice(0, 20);
            displayPlaces(currentPlaces);
            addMarkersToMap(currentPlaces, userLocation);
        }
    });
}

// Show Place Details
function showPlaceDetails(placeId) {
    const request = {
        placeId: placeId,
        fields: ['name', 'rating', 'formatted_phone_number', 'formatted_address', 'website', 'opening_hours', 'photos', 'reviews', 'price_level']
    };
    
    service.getDetails(request, (place, status) => {
        if (status === google.maps.places.PlacesServiceStatus.OK) {
            displayPlaceModal(place);
        }
    });
}

// Display Place Modal
function displayPlaceModal(place) {
    document.getElementById('placeModalTitle').textContent = place.name;
    
    const photos = place.photos ? place.photos.slice(0, 3).map(photo => 
        `<img src="${photo.getUrl({maxWidth: 300})}" class="img-fluid rounded mb-2" alt="${place.name}">`
    ).join('') : '';
    
    const reviews = place.reviews ? place.reviews.slice(0, 2).map(review => `
        <div class="review mb-3 p-3 bg-light rounded">
            <div class="d-flex justify-content-between mb-2">
                <strong>${review.author_name}</strong>
                <span class="text-warning">${'★'.repeat(review.rating)}${'☆'.repeat(5-review.rating)}</span>
            </div>
            <p class="mb-0">${review.text}</p>
        </div>
    `).join('') : '';
    
    document.getElementById('placeModalBody').innerHTML = `
        ${photos}
        ${place.rating ? `<p><strong>Đánh giá:</strong> ${place.rating}/5 ⭐</p>` : ''}
        ${place.formatted_address ? `<p><strong>Địa chỉ:</strong> ${place.formatted_address}</p>` : ''}
        ${place.formatted_phone_number ? `<p><strong>Điện thoại:</strong> ${place.formatted_phone_number}</p>` : ''}
        ${place.website ? `<p><strong>Website:</strong> <a href="${place.website}" target="_blank">${place.website}</a></p>` : ''}
        ${place.opening_hours ? `<p><strong>Giờ mở cửa:</strong><br>${place.opening_hours.weekday_text.join('<br>')}</p>` : ''}
        ${reviews ? `<h6 class="mt-4">Đánh giá gần đây:</h6>${reviews}` : ''}
    `;
    
    const modal = new bootstrap.Modal(document.getElementById('placeModal'));
    modal.show();
}

// Utility Functions
function calculateDistance(pos1, pos2) {
    const lat1 = pos1.lat;
    const lng1 = pos1.lng;
    const lat2 = pos2.lat();
    const lng2 = pos2.lng();
    
    const R = 6371; // Earth's radius in km
    const dLat = (lat2 - lat1) * Math.PI / 180;
    const dLng = (lng2 - lng1) * Math.PI / 180;
    const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
              Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
              Math.sin(dLng/2) * Math.sin(dLng/2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
    return R * c;
}

function getPlaceTypeInVietnamese(type) {
    const typeMap = {
        'restaurant': 'Nhà hàng',
        'tourist_attraction': 'Điểm tham quan',
        'lodging': 'Khách sạn',
        'shopping_mall': 'Trung tâm mua sắm',
        'park': 'Công viên',
        'museum': 'Bảo tàng',
        'hospital': 'Bệnh viện',
        'gas_station': 'Cây xăng',
        'bank': 'Ngân hàng'
    };
    return typeMap[type] || 'Địa điểm';
}

function showLocationError() {
    const placesList = document.getElementById('placesList');
    placesList.innerHTML = `
        <div class="text-center py-4">
            <i class="fas fa-exclamation-triangle text-warning fa-2x mb-3"></i>
            <p>Không thể lấy vị trí của bạn. Sử dụng vị trí mặc định.</p>
            <button class="btn btn-primary btn-sm" onclick="getUserLocation()">Thử lại</button>
        </div>
    `;
}

function showNoResultsMessage() {
    const placesList = document.getElementById('placesList');
    placesList.innerHTML = `
        <div class="text-center py-4">
            <i class="fas fa-search text-muted fa-2x mb-3"></i>
            <p>Không tìm thấy địa điểm nào trong khu vực này.</p>
        </div>
    `;
}
