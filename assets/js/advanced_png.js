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

function drawGrayscale(imageData, image, maxThreshold) {
    for (let i = 0; i < image.numPixels; i++) {
        const value = (Math.min(image.typedData[i], maxThreshold) / maxThreshold) * 255;
        const canvasIndex = i * 4;
        imageData.data[canvasIndex + 0] = value; // R
        imageData.data[canvasIndex + 1] = value; // G
        imageData.data[canvasIndex + 2] = value; // B
        imageData.data[canvasIndex + 3] = 255;   // A
    }
}

function drawRGBA(imageData, image, maxThreshold) {
    for (let i = 0; i < image.data.length; i++) {
        const clamped = Math.min(image.data[i], maxThreshold);
        const mapped = (clamped / maxThreshold) * 255;
        imageData.data[i] = mapped;
    }
}

function render(canvas, image, maxThreshold) {
    const context = canvas.getContext('2d');
    const imageData = context.getImageData(0, 0, canvas.width, canvas.height);

    switch (image.ctype) {
        case 0:
            drawGrayscale(imageData, image, maxThreshold);
            break;
        case 6:
            drawRGBA(imageData, image, maxThreshold);
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
            this.maxThreshold = 1000;

            const url = '/object-image/' + this.el.dataset.objectId;
            fetch(url)
                .then(res => res.blob())
                .then(blob => blob.arrayBuffer())
                .then(buf => {
                    this.image = decode(buf);

                    this.el.width = this.image.width;
                    this.el.height = this.image.height;
                })
                .then(() => render(this.el, this.image, (this.maxThreshold / 1000) * this.image.maxValue))

            document.getElementById('advanced-png-viewer-max-slider').addEventListener('input', ev => {
                this.maxThreshold = ev.currentTarget.value;
                if (this.image) render(this.el, this.image, (this.maxThreshold / 1000) * this.image.maxValue);
            });
        }
    }
}
