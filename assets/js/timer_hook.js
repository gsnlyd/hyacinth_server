export function createHook() {
    return {
        mounted() {
            this.startTimestampSeconds = parseInt(this.el.dataset.timestamp);
            this.displayEl = document.getElementById('label-timer-display');
            this.timeoutId = null;

            this.runTimer = () => {
                const secondsElapsed = (Date.now() / 1000) - this.startTimestampSeconds;
                const secondsUntilNext = 1 - (secondsElapsed % 1);

                const displayMinutes = Math.floor(secondsElapsed / 60);
                const displaySeconds = Math.floor(secondsElapsed % 60);
                this.displayEl.innerHTML = displayMinutes + ':' + String(displaySeconds).padStart(2, '0');

                this.timeoutId = setTimeout(() => this.runTimer(), secondsUntilNext * 1000);
            }
            this.runTimer();
        },
        updated() {
            const newStartTimestampSeconds = parseInt(this.el.dataset.timestamp);
            if (newStartTimestampSeconds != this.startTimestampSeconds) {
                this.startTimestampSeconds = newStartTimestampSeconds;
                if (this.timeoutId !== null) {
                    clearTimeout(this.timeoutId);
                    this.runTimer();
                }
            }
        },
        destroyed() {
            if (this.timeoutId !== null) clearTimeout(this.timeoutId);
        }
    }
}
