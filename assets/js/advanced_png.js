function computeStats(image) {
    var min = image.data[0];
    var max = image.data[0];

    for (const val of image.data) {
        if (val < min) min = val;
        if (val > max) max = val;
    }

    return {min, max};
}

function render(canvas, image, maxThreshold) {
    const context = canvas.getContext('2d');
    const imageData = context.getImageData(0, 0, canvas.width, canvas.height);

    for (let i = 0; i < image.data.length; i++) {
        const clamped = Math.min(image.data[i], maxThreshold);
        const mapped = (clamped / maxThreshold) * 255;
        imageData.data[i] = mapped;
    }

    context.putImageData(imageData, 0, 0);
}

export function createHook() {
    return {
        mounted() {
            this.image = null;
            this.imageStats = null;
            this.maxThreshold = 255;

            const url = '/object-image/' + this.el.dataset.objectId;
            fetch(url)
                .then(res => res.blob())
                .then(blob => blob.arrayBuffer())
                .then(buf => {
                    this.image = UPNG.decode(buf)
                    this.imageStats = computeStats(this.image);

                    this.el.width = this.image.width;
                    this.el.height = this.image.height;
                })
                .then(() => render(this.el, this.image, this.maxThreshold))

            document.getElementById('advanced-png-viewer-max-slider').addEventListener('input', ev => {
                this.maxThreshold = ev.currentTarget.value;
                if (this.image) {
                    render(this.el, this.image, this.maxThreshold);
                }
            });
        }
    }
}
