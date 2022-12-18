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
    for (let i = 0; i < image.data.length; i++) {
        const clamped = Math.max(Math.min(image.data[i], maxThreshold), minThreshold);
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

export function createHook() {
    return {
        mounted() {
            this.image = null;
            this.minThreshold = 0;
            this.maxThreshold = 100;

            this.minSliderEl = document.getElementById('advanced-png-viewer-min-slider');
            this.minInputEl = document.getElementById('advanced-png-viewer-min-input');
            this.maxSliderEl = document.getElementById('advanced-png-viewer-max-slider');
            this.maxInputEl = document.getElementById('advanced-png-viewer-max-input');

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
                    this.minSliderEl.value = this.image.minValue;
                    this.minInputEl.min = this.image.minValue;
                    this.minInputEl.max = this.image.maxValue;
                    this.minInputEl.value = this.image.minValue;

                    this.minThreshold = this.image.minValue;

                    this.maxSliderEl.min = this.image.minValue;
                    this.maxSliderEl.max = this.image.maxValue;
                    this.maxSliderEl.value = this.image.maxValue;
                    this.maxInputEl.min = this.image.minValue;
                    this.maxInputEl.max = this.image.maxValue;
                    this.maxInputEl.value = this.image.maxValue;

                    this.maxThreshold = this.image.maxValue;

                    render(this.el, this.image, this.minThreshold, this.maxThreshold);
                });

            updateMinThreshold = (minThreshold) => {
                minThreshold = parseInt(minThreshold);
                if (minThreshold >= this.maxThreshold) minThreshold = this.maxThreshold - 1;
                this.minThreshold = minThreshold;
                this.minSliderEl.value = minThreshold;
                this.minInputEl.value = minThreshold;
                if (this.image) render(this.el, this.image, this.minThreshold, this.maxThreshold);
            }

            this.minSliderEl.addEventListener('input', ev => updateMinThreshold(ev.currentTarget.value));
            this.minInputEl.addEventListener('change', ev => updateMinThreshold(ev.currentTarget.value));

            updateMaxThreshold = (maxThreshold) => {
                maxThreshold = parseInt(maxThreshold);
                if (maxThreshold <= this.minThreshold) maxThreshold = this.minThreshold + 1;
                this.maxThreshold = maxThreshold;
                this.maxSliderEl.value = maxThreshold;
                this.maxInputEl.value = maxThreshold;
                if (this.image) render(this.el, this.image, this.minThreshold, this.maxThreshold);
            }

            this.maxSliderEl.addEventListener('input', ev => updateMaxThreshold(ev.currentTarget.value));
            this.maxInputEl.addEventListener('change', ev => updateMaxThreshold(ev.currentTarget.value));
        }
    }
}
