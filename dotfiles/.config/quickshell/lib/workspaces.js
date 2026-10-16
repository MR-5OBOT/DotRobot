function workspaceIndex(workspace) {
    if (!workspace) return -1;
    if (workspace.name === "0") return 0;
    return workspace.id >= 1 && workspace.id <= 10 ? workspace.id : -1;
}

function containsWindow(client, index) {
    return client.mapped && !client.hidden && client.size && client.at
        && client.size[0] > 0 && client.size[1] > 0
        && workspaceIndex(client.workspace) === index;
}

function move(index, step, columns, count) {
    if (Math.abs(step) === 1) return (index + step + count) % count;
    var column = index % columns;
    var rows = Math.floor((count - 1 - column) / columns) + 1;
    var row = Math.floor(index / columns);
    return ((row + (step > 0 ? 1 : -1) + rows) % rows) * columns + column;
}

function occupiedWorkspaces(clients) {
    var occupied = [];
    for (const client of clients) {
        var index = workspaceIndex(client.workspace);
        if (index >= 0 && containsWindow(client, index) && occupied.indexOf(index) === -1)
            occupied.push(index);
    }
    return occupied.sort((a, b) => a - b);
}

function monitorGeometry(monitor) {
    var rotated = (monitor.transform || 0) % 2 === 1;
    return {
        x: monitor.x, y: monitor.y,
        width: (rotated ? monitor.height : monitor.width) / monitor.scale,
        height: (rotated ? monitor.width : monitor.height) / monitor.scale
    };
}

function focusRequest(index) {
    // Hyprland's numbered workspaces start at 1; 0 is a named workspace.
    return 'hl.dsp.focus({ workspace = ' + (index === 0 ? '"name:0"' : index) + ' })';
}
