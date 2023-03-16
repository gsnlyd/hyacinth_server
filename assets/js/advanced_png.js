import UPNG from '../vendor/upng/UPNG.js';

function decode(buffer) {
    const image = UPNG.decode(buffer);

    image.numPixels = image.width * image.height;

    let typedData;
    switch (image.depth) {
        case 8:
            typedData = image.data;
            break;
        case 16:
            typedData = new Uint16Array(image.numPixels);
            for (let i = 0; i < image.numPixels; i++) {
                const byteIndex = i * 2;
                typedData[i] = (image.data[byteIndex] << 8) | image.data[byteIndex + 1];
            }
            break;
        default:
            throw new Error(`Unsupported depth: ${image.depth}`);
    }
    image.typedData = typedData;

    let minValue = image.typedData[0];
    let maxValue = image.typedData[0];

    for (const val of image.typedData) {
        if (val < minValue) minValue = val;
        if (val > maxValue) maxValue = val;
    }

    image.minValue = minValue;
    image.maxValue = maxValue;

    return image;
}

function drawGrayscale(imageData, image, minThreshold, maxThreshold) {
    for (let i = 0; i < image.numPixels; i++) {
        const clamped = Math.max(Math.min(image.typedData[i], maxThreshold), minThreshold);
        const value = ((clamped - minThreshold) / (maxThreshold - minThreshold)) * 255;
        const canvasIndex = i * 4;
        imageData.data[canvasIndex + 0] = value; // R
        imageData.data[canvasIndex + 1] = value; // G
        imageData.data[canvasIndex + 2] = value; // B
        imageData.data[canvasIndex + 3] = 255;   // A
    }
}

function drawRGBA(imageData, image, minThreshold, maxThreshold) {
    // TODO: this actually tone-maps the alpha values, which is clearly
    // wrong but doesn't matter because they're usually all set to 255
    // Still, this should probably be fixed
    for (let i = 0; i < image.typedData.length; i++) {
        const clamped = Math.max(Math.min(image.typedData[i], maxThreshold), minThreshold);
        const value = ((clamped - minThreshold) / (maxThreshold - minThreshold)) * 255;
        imageData.data[i] = value;
    }
}

function render(canvas, image, minThreshold, maxThreshold) {
    const context = canvas.getContext('2d');
    const imageData = context.getImageData(0, 0, canvas.width, canvas.height);

    switch (image.ctype) {
        case 0:
            drawGrayscale(imageData, image, minThreshold, maxThreshold);
            break;
        case 6:
            drawRGBA(imageData, image, minThreshold, maxThreshold);
            break;
        default:
            throw new Error(`Unsupported png color type: ${image.ctype}`)
    }

    context.putImageData(imageData, 0, 0);
}

function getRegionStatsGrayscale(image, x1, x2, y1, y2) {
    const width = image.width;

    let min = image.typedData[x1 + y1 * width];
    let max = image.typedData[x1 + y1 * width];

    for (let x = x1; x < x2; x++) {
        for (let y = y1; y < y2; y++) {
            const value = image.typedData[x + y * width];
            if (value < min) min = value;
            if (value > max) max = value;
        }
    }

    return {
        minValue: min,
        maxValue: max,
    };
}

function getRegionStatsRGBA(image, x1, x2, y1, y2) {
    const width = image.width;

    let min = image.typedData[(x1 + y1 * width) * 4];
    let max = min;

    for (let x = x1; x < x2; x++) {
        for (let y = y1; y < y2; y++) {
            for (let c = 0; c < 3; c++) {
                const value = image.typedData[((x + y * width) * 4) + c];
                if (value < min) min = value;
                if (value > max) max = value;
            }
        }
    }

    return {
        minValue: min,
        maxValue: max,
    };
}

function getRegionStats(canvas, image, rectPageCoords) {
    const {x: x1, y: y1} = getCanvasCoordinates(canvas, rectPageCoords.x1, rectPageCoords.y1);
    const {x: x2, y: y2} = getCanvasCoordinates(canvas, rectPageCoords.x2, rectPageCoords.y2);

    switch (image.ctype) {
        case 0: return getRegionStatsGrayscale(image, x1, x2, y1, y2);
        case 6: return getRegionStatsRGBA(image, x1, x2, y1, y2);
        default: throw new Error(`Unsupported png color type: ${image.ctype}`);
    }
}

function getTrueCanvasRect(canvas) {
    // This function returns the canvas's true
    // width/height/x/y relative to the canvas element
    // after accounting for the CSS "object-fit: contain;"
    // property
    const containWidth = canvas.scrollWidth;
    const containHeight = canvas.scrollHeight;
    const canvasWidth = canvas.width;
    const canvasHeight = canvas.height;

    const containRatio = containWidth / containHeight;
    const canvasRatio = canvasWidth / canvasHeight;

    let width;
    let height;
    if (canvasRatio > containRatio) {
        width = containWidth;
        height = width / canvasRatio;
    }
    else {
        height = containHeight;
        width = height * canvasRatio;
    }

    const x = Math.floor((containWidth - width) / 2);
    const y = Math.floor((containHeight - height) / 2);

    return {width, height, x, y};
}

function getCanvasCoordinates(canvas, pageX, pageY) {
    // Canvas element full bounding rect
    const rect = canvas.getBoundingClientRect();
    // Canvas bounding rect relative to above rect
    // after taking "object-fit: contain" into account
    const trueRect = getTrueCanvasRect(canvas);

    // True canvas x/y in page coordinates
    const trueCanvasPageX = rect.x + trueRect.x;
    const trueCanvasPageY = rect.y + trueRect.y;

    // Input coords (pageX/pageY) relative to true canvas
    // but still in page pixel units
    const xPagePixels = pageX - trueCanvasPageX;
    const yPagePixels = pageY - trueCanvasPageY;

    // Input coords relative to true canvas in canvas coordinates
    const xCanvasPixels = Math.floor((xPagePixels / trueRect.width) * canvas.width);
    const yCanvasPixels = Math.floor((yPagePixels / trueRect.height) * canvas.height);

    return {
        x: xCanvasPixels,
        y: yCanvasPixels,
    };
}

function computeRect(x1, y1, x2, y2) {
    // Computes bounding rect, re-ordering
    // values to avoid a negative width/height
    const newX1 = Math.min(x1, x2);
    const newX2 = Math.max(x1, x2);
    const newY1 = Math.min(y1, y2);
    const newY2 = Math.max(y1, y2);

    return {
        x: newX1,
        y: newY1,
        x1: newX1,
        y1: newY1,
        x2: newX2,
        y2: newY2,
        width: newX2 - newX1,
        height: newY2 - newY1,
    };
}

export function createHook() {
    return {
        mounted() {
            this.image = null;
            this.dragOrigin = null;

            const uniqueId = this.el.dataset.uniqueId;
            const collaborationEnabled = this.el.dataset.collaborationEnabled === "true";
            this.dragBoxEl = document.getElementById('advanced-png-viewer-drag-box-' + uniqueId);

            this.minSliderEl = document.getElementById('advanced-png-viewer-min-slider-' + uniqueId);
            this.minInputEl = document.getElementById('advanced-png-viewer-min-input-' + uniqueId);
            this.maxSliderEl = document.getElementById('advanced-png-viewer-max-slider-' + uniqueId);
            this.maxInputEl = document.getElementById('advanced-png-viewer-max-input-' + uniqueId);

            const url = '/object-image/' + this.el.dataset.objectId;
            fetch(url)
                .then(res => res.blob())
                .then(blob => blob.arrayBuffer())
                .then(buf => {
                    this.image = decode(buf);

                    this.el.width = this.image.width;
                    this.el.height = this.image.height;
                })
                .then(() => {
                    this.minSliderEl.min = this.image.minValue;
                    this.minSliderEl.max = this.image.maxValue;
                    this.minInputEl.min = this.image.minValue;
                    this.minInputEl.max = this.image.maxValue;

                    this.maxSliderEl.min = this.image.minValue;
                    this.maxSliderEl.max = this.image.maxValue;
                    this.maxInputEl.min = this.image.minValue;
                    this.maxInputEl.max = this.image.maxValue;

                    initializeState({
                        minThreshold: this.image.minValue,
                        maxThreshold: this.image.maxValue,
                    });
                });

            this.viewerState = {};

            this.handleEvent('viewer_state_pushed', data => {
                if (data.uniqueId.toString() === uniqueId) updateState(data.state, false);
            });

            const initializeState = (initialState) => {
                if (Object.keys(this.viewerState).length === 0) {
                    mergeState(initialState);
                    broadcastState('viewer_state_initialized');
                }
                updateViewer();
            }

            const updateState = (newState, broadcast=true) => {
                mergeState(newState);
                if (broadcast) broadcastState('viewer_state_updated');
                updateViewer();
            }

            const mergeState = (newState) => {
                for (const [k, v] of Object.entries(newState)) {
                    this.viewerState[k] = v;
                }
            }

            const broadcastState = (eventName) => {
                if (collaborationEnabled) this.pushEvent(eventName, this.viewerState);
            }

            const updateViewer = () => {
                if (this.image) render(this.el, this.image, this.viewerState.minThreshold, this.viewerState.maxThreshold);

                this.minSliderEl.value = this.viewerState.minThreshold;
                this.minInputEl.value = this.viewerState.minThreshold;
                this.maxSliderEl.value = this.viewerState.maxThreshold;
                this.maxInputEl.value = this.viewerState.maxThreshold;
            }

            const updateMinThreshold = (minThreshold) => {
                minThreshold = Math.min(parseInt(minThreshold), this.viewerState.maxThreshold - 1);
                updateState({minThreshold});
            }

            this.minSliderEl.addEventListener('input', ev => updateMinThreshold(ev.currentTarget.value));
            this.minInputEl.addEventListener('change', ev => updateMinThreshold(ev.currentTarget.value));

            const updateMaxThreshold = (maxThreshold) => {
                maxThreshold = Math.max(parseInt(maxThreshold), this.viewerState.minThreshold + 1);
                updateState({maxThreshold});
            }

            this.maxSliderEl.addEventListener('input', ev => updateMaxThreshold(ev.currentTarget.value));
            this.maxInputEl.addEventListener('change', ev => updateMaxThreshold(ev.currentTarget.value));

            const renderDrag = (mouseCoords) => {
                if (this.dragOrigin) {
                    const rect = computeRect(this.dragOrigin.pageX, this.dragOrigin.pageY, mouseCoords.pageX, mouseCoords.pageY);

                    this.dragBoxEl.style.left = rect.x + 'px';
                    this.dragBoxEl.style.top = rect.y + 'px';
                    this.dragBoxEl.style.width = rect.width + 'px';
                    this.dragBoxEl.style.height = rect.height + 'px';
                }
            };

            const updateStatsForRegion = (mouseCoords) => {
                if (this.dragOrigin) {
                    const rect = computeRect(this.dragOrigin.pageX, this.dragOrigin.pageY, mouseCoords.pageX, mouseCoords.pageY);
                    const regionStats = getRegionStats(this.el, this.image, rect);
                    updateMinThreshold(regionStats.minValue);
                    updateMaxThreshold(regionStats.maxValue);
                }
            }

            this.el.addEventListener('mousedown', ev => {
                this.dragOrigin = {pageX: ev.pageX, pageY: ev.pageY};
                renderDrag(this.dragOrigin);
                this.dragBoxEl.classList.remove('hidden');
            });

            this.el.addEventListener('mouseup', ev => {
                updateStatsForRegion({pageX: ev.pageX, pageY: ev.pageY});
                this.dragBoxEl.classList.add('hidden');
                this.dragOrigin = null;
            });

            this.el.addEventListener('mousemove', ev => {
                renderDrag({pageX: ev.pageX, pageY: ev.pageY});
            });
        }
    }
}
