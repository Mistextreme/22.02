let stashes = [];
let currentLang = 'en';

const translations = {
    en: {
        title: 'Stash Admin Panel',
        listTab: 'Stash List',
        createTab: 'Create Stash',
        searchPlaceholder: 'Search stashes...',
        createTitle: 'Create New Stash',
        stashId: 'Stash ID',
        stashIdPlaceholder: 'e.g. police_storage',
        label: 'Label',
        labelPlaceholder: 'e.g. Police Storage',
        slots: 'Slots',
        weight: 'Weight',
        code: 'Code',
        codePlaceholder: 'Enter code',
        rotation: 'Rotation',
        coordinates: 'Coordinates',
        myPosition: 'My Position',
        zoneSize: 'Zone Size',
        debugMode: 'Debug Mode',
        create: 'Create Stash',
        editTitle: 'Edit Stash',
        save: 'Save',
        cancel: 'Cancel',
        noStashes: 'No stashes created',
        id: 'ID',
        coords: 'Coords',
        view: 'View'
    },
};

function t(key) {
    return translations[currentLang][key] || translations['en'][key] || key;
}

function setLanguage(lang) {
    if (translations[lang]) {
        currentLang = lang;
        updateUI();
        localStorage.setItem('stash_lang', lang);
    }
}

function updateUI() {
    document.querySelector('.header h1').innerHTML = `<i class="fas fa-box"></i> ${t('title')}`;
    
    document.querySelector('[data-tab="list"]').innerHTML = `<i class="fas fa-list"></i> ${t('listTab')}`;
    document.querySelector('[data-tab="create"]').innerHTML = `<i class="fas fa-plus"></i> ${t('createTab')}`;
    
    document.getElementById('searchInput').placeholder = t('searchPlaceholder');
    
    document.querySelector('#createForm h2').textContent = t('createTitle');
    document.querySelector('label[for="create_stash_id"]').textContent = t('stashId');
    document.getElementById('create_stash_id').placeholder = t('stashIdPlaceholder');
    document.querySelector('label[for="create_label"]').textContent = t('label');
    document.getElementById('create_label').placeholder = t('labelPlaceholder');
    document.querySelector('label[for="create_slots"]').textContent = t('slots');
    document.querySelector('label[for="create_weight"]').textContent = t('weight');
    document.querySelector('label[for="create_code"]').textContent = t('code');
    document.getElementById('create_code').placeholder = t('codePlaceholder');
    document.querySelector('label[for="create_rotation"]').textContent = t('rotation');
    document.querySelector('label[for="create_debug"]').textContent = t('debugMode');
    document.querySelector('#createForm .btn-primary').innerHTML = `<i class="fas fa-plus"></i> ${t('create')}`;
    
    const coordsSections = document.querySelectorAll('.coords-section h3');
    coordsSections.forEach((section, index) => {
        if (index % 2 === 0) {
            section.innerHTML = `${t('coordinates')} <button type="button" class="btn-small" onclick="getPlayerCoords('${section.closest('form').id === 'createForm' ? 'create' : 'edit'}')"><i class="fas fa-crosshairs"></i> ${t('myPosition')}</button>`;
        } else {
            section.textContent = t('zoneSize');
        }
    });
    
    document.querySelector('.modal-header h2').textContent = t('editTitle');
    document.querySelector('label[for="edit_label"]').textContent = t('label');
    document.querySelector('label[for="edit_code"]').textContent = t('code');
    document.querySelector('label[for="edit_slots"]').textContent = t('slots');
    document.querySelector('label[for="edit_weight"]').textContent = t('weight');
    document.querySelector('label[for="edit_rotation"]').textContent = t('rotation');
    document.querySelector('label[for="edit_debug"]').textContent = t('debugMode');
    document.querySelector('#editForm .btn-primary').innerHTML = `<i class="fas fa-save"></i> ${t('save')}`;
    document.querySelector('#editForm .btn-secondary').textContent = t('cancel');
    
    renderStashList();
}

window.addEventListener('message', function(event) {
    const data = event.data;
    
    switch(data.action) {
        case 'openUI':
            document.getElementById('app').classList.remove('hidden');
            stashes = data.stashes || [];
            if (data.lang) setLanguage(data.lang);
            renderStashList();
            break;
        case 'closeUI':
            document.getElementById('app').classList.add('hidden');
            break;
        case 'refreshStashes':
            stashes = data.stashes || [];
            renderStashList();
            break;
        case 'setLanguage':
            setLanguage(data.lang);
            break;
    }
});

document.addEventListener('DOMContentLoaded', function() {
    const savedLang = localStorage.getItem('stash_lang');
    if (savedLang && translations[savedLang]) {
        currentLang = savedLang;
    }
    updateUI();
});

document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape') {
        closeUI();
    }
});

document.querySelectorAll('.tab-btn').forEach(btn => {
    btn.addEventListener('click', function() {
        const tab = this.dataset.tab;
        
        document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
        document.querySelectorAll('.tab-content').forEach(t => t.classList.remove('active'));
        
        this.classList.add('active');
        document.getElementById(tab + '-tab').classList.add('active');
    });
});

function closeUI() {
    document.getElementById('app').classList.add('hidden');
    fetch('https://UniqueDevelopment_StashCreator/close', {
        method: 'POST',
        body: JSON.stringify({})
    });
}

function renderStashList() {
    const container = document.getElementById('stashList');
    
    if (stashes.length === 0) {
        container.innerHTML = `
            <div class="empty-state">
                <i class="fas fa-box-open"></i>
                <p>${t('noStashes')}</p>
            </div>
        `;
        return;
    }
    
    container.innerHTML = stashes.map(stash => `
        <div class="stash-item" data-id="${stash.stash_id}">
            <div class="stash-info">
                <h3>${stash.label}</h3>
                <p>${t('id')}: <span>${stash.stash_id}</span> | ${t('slots')}: <span>${stash.slots}</span> | ${t('weight')}: <span>${stash.weight}kg</span></p>
                <p>${t('coords')}: ${stash.coords.x.toFixed(2)}, ${stash.coords.y.toFixed(2)}, ${stash.coords.z.toFixed(2)}</p>
            </div>
            <div class="stash-actions">
                <button class="btn-view" onclick="viewStash('${stash.stash_id}')" title="${t('view')}"><i class="fas fa-eye"></i></button>
                <button class="btn-edit" onclick="openEditModal('${stash.stash_id}')"><i class="fas fa-edit"></i></button>
                <button class="btn-teleport" onclick="teleportToStash('${stash.stash_id}')"><i class="fas fa-location-arrow"></i></button>
                <button class="btn-delete" onclick="deleteStash('${stash.stash_id}')"><i class="fas fa-trash"></i></button>
            </div>
        </div>
    `).join('');
}

function filterStashes() {
    const searchTerm = document.getElementById('searchInput').value.toLowerCase();
    const items = document.querySelectorAll('.stash-item');
    
    items.forEach(item => {
        const text = item.textContent.toLowerCase();
        item.style.display = text.includes(searchTerm) ? 'flex' : 'none';
    });
}

function getPlayerCoords(prefix) {
    fetch('https://UniqueDevelopment_StashCreator/getPlayerCoords', {
        method: 'POST',
        body: JSON.stringify({})
    })
    .then(resp => resp.json())
    .then(coords => {
        document.getElementById(prefix + '_coords_x').value = coords.x.toFixed(4);
        document.getElementById(prefix + '_coords_y').value = coords.y.toFixed(4);
        document.getElementById(prefix + '_coords_z').value = coords.z.toFixed(4);
    });
}

document.getElementById('createForm').addEventListener('submit', function(e) {
    e.preventDefault();
    
    const data = {
        stash_id: document.getElementById('create_stash_id').value,
        label: document.getElementById('create_label').value,
        slots: parseInt(document.getElementById('create_slots').value),
        weight: parseInt(document.getElementById('create_weight').value),
        code: document.getElementById('create_code').value,
        rotation: parseFloat(document.getElementById('create_rotation').value),
        coords: {
            x: parseFloat(document.getElementById('create_coords_x').value),
            y: parseFloat(document.getElementById('create_coords_y').value),
            z: parseFloat(document.getElementById('create_coords_z').value)
        },
        size: {
            x: parseFloat(document.getElementById('create_size_x').value),
            y: parseFloat(document.getElementById('create_size_y').value),
            z: parseFloat(document.getElementById('create_size_z').value)
        },
        debug: document.getElementById('create_debug').checked
    };
    
    fetch('https://UniqueDevelopment_StashCreator/createStash', {
        method: 'POST',
        body: JSON.stringify(data)
    })
    .then(resp => resp.json())
    .then(result => {
        if (result.success) {
            document.getElementById('createForm').reset();
            document.querySelector('[data-tab="list"]').click();
            refreshStashes();
        }
    });
});

function openEditModal(stashId) {
    const stash = stashes.find(s => s.stash_id === stashId);
    if (!stash) return;
    
    document.getElementById('edit_stash_id').value = stash.stash_id;
    document.getElementById('edit_label').value = stash.label;
    document.getElementById('edit_code').value = stash.code;
    document.getElementById('edit_slots').value = stash.slots;
    document.getElementById('edit_weight').value = stash.weight;
    document.getElementById('edit_rotation').value = stash.rotation || 0;
    document.getElementById('edit_coords_x').value = stash.coords.x;
    document.getElementById('edit_coords_y').value = stash.coords.y;
    document.getElementById('edit_coords_z').value = stash.coords.z;
    document.getElementById('edit_size_x').value = stash.size.x;
    document.getElementById('edit_size_y').value = stash.size.y;
    document.getElementById('edit_size_z').value = stash.size.z;
    document.getElementById('edit_debug').checked = stash.debug;
    
    document.getElementById('editModal').classList.remove('hidden');
}

function closeEditModal() {
    document.getElementById('editModal').classList.add('hidden');
}

document.getElementById('editForm').addEventListener('submit', function(e) {
    e.preventDefault();
    
    const data = {
        stash_id: document.getElementById('edit_stash_id').value,
        label: document.getElementById('edit_label').value,
        code: document.getElementById('edit_code').value,
        slots: parseInt(document.getElementById('edit_slots').value),
        weight: parseInt(document.getElementById('edit_weight').value),
        rotation: parseFloat(document.getElementById('edit_rotation').value),
        coords: {
            x: parseFloat(document.getElementById('edit_coords_x').value),
            y: parseFloat(document.getElementById('edit_coords_y').value),
            z: parseFloat(document.getElementById('edit_coords_z').value)
        },
        size: {
            x: parseFloat(document.getElementById('edit_size_x').value),
            y: parseFloat(document.getElementById('edit_size_y').value),
            z: parseFloat(document.getElementById('edit_size_z').value)
        },
        debug: document.getElementById('edit_debug').checked
    };
    
    fetch('https://UniqueDevelopment_StashCreator/updateStash', {
        method: 'POST',
        body: JSON.stringify(data)
    })
    .then(resp => resp.json())
    .then(result => {
        if (result.success) {
            closeEditModal();
            refreshStashes();
        }
    });
});

function deleteStash(stashId) {
    fetch('https://UniqueDevelopment_StashCreator/deleteStash', {
        method: 'POST',
        body: JSON.stringify({ stash_id: stashId })
    })
    .then(resp => resp.json())
    .then(result => {
        if (result.success) {
            refreshStashes();
        }
    });
}

function teleportToStash(stashId) {
    const stash = stashes.find(s => s.stash_id === stashId);
    if (!stash) return;
    
    fetch('https://UniqueDevelopment_StashCreator/teleportToStash', {
        method: 'POST',
        body: JSON.stringify({ coords: stash.coords })
    });
}

function viewStash(stashId) {
    fetch('https://UniqueDevelopment_StashCreator/viewStash', {
        method: 'POST',
        body: JSON.stringify({ stash_id: stashId })
    });
}

function refreshStashes() {
    fetch('https://UniqueDevelopment_StashCreator/getStashes', {
        method: 'POST',
        body: JSON.stringify({})
    })
    .then(resp => resp.json())
    .then(data => {
        stashes = data;
        renderStashList();
    });
}